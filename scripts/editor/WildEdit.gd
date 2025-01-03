class_name WildEdit extends CodeEdit

var is_active = false

const Boom: PackedScene    = preload("res://effects/boom.tscn")
const Combo: PackedScene   = preload("res://effects/combo.tscn")
const Laser: PackedScene   = preload("res://effects/laser.tscn")
const Blip: PackedScene    = preload("res://effects/blip.tscn")
const Newline: PackedScene = preload("res://effects/newline.tscn")

var effects = {
    level=1,
    combo=1,
    combo_shot=1,
    audio=1,
    shake=1,
    chars=1,
    delete=1,
    newline=1,
    particles=1,
}

var shake: float = 0.0
var shake_intensity:float  = 0.0
var pitch_increase: float = 0.0

var caret_line := 0
var caret_column := 0

var last_line: String = ''
var last_unicode: String = ''
var last_key_name: String = ''
var last_text: String = ''
var last_caret_line: = 0

const TIME_BOOM_INTERVAL = 0.1
const TIME_CHAR_INTERVAL = 0.1
var _time_b: float = 0.0
# var _time_c: float = 0.0
var font_size := 0 # the setting in basic


var ime
var ime_display

var skip_effect = false
var is_single_letter = false

var is_ime_input = false

var ime_state = {
    compose_id = "",
    is_composing = false,      # 是否正在输入中
    last_compose = "",         # 上一次的混合文本
    last_non_empty = "",       # 上一次非空的混合文本
    pending_finish = false,    # 是否有待处理的完成事件
    pending_cancel = false,    # 是否有待处理的取消事件
    last_update_time = 0,      # 最后更新时间
    last_finish_time = 0,      # 最后完成时间
    first_input = "",          # 输入序列的第一个字符
    input_sequence = "",       # 完整的输入序列
}

var combo_node: Control
var compose_nodes : = {}
# var compose_node_pool :  = []
# var compose_node_pool_size := 4

func _get_ime_compose(id=''):
    # var id = ime_state.compose_id
    if id in compose_nodes:
        return compose_nodes[id]
    var node = IMECompose.new()
    node.z_index = 10
    # add_child(node)
    add_child.call_deferred(node)
    update_compose_position(node)
    compose_nodes[id] = node
    return node
func _free_ime_compose(id=''):
    if id in compose_nodes:
        var nd = compose_nodes[id]
        compose_nodes.erase(id)
        nd.set_text('')
        await Util.wait(1.0)
        nd.queue_free()
    else:
        push_error('free invalid id', id)

func _has_ime_compose(id=''):
    return compose_nodes.has(id)



func _ready():
    print('WildEdit inited')

    gui_input.connect(_on_gui_input)
    text_changed.connect(_otc)
    text_changed.connect(_on_text_changed)
    caret_changed.connect(_on_caret_changed)

    ime_display = preload("res://scenes/ime_display.tscn").instantiate()
    ime_display.hide()
    add_child(ime_display)

    ime = TinyIME
    ime_display.feed_ime_input.connect(feed_ime_input)
    ime.ime_state_changed.connect(func(v):
        if !is_active: return
        if v:
            # ime_button.text = 'CN'
            ime_display.show()
            update_ime_position()
        else:
            # ime_button.text = 'EN'
            ime_display.hide()
    )
    caret_changed.connect(update_ime_position)
    # caret_changed.connect(update_compose_position)

    ime.ime_buffer_changed.connect(_on_ime_buffer_changed)

func update_ime_position():
    if !is_active: return
    if ime_display == null: return
    if ime_display.visible:
        await get_tree().process_frame
        var line_height = get_line_height()
        var ime_height = ime_display.size.y
        var caret_pos = _gfcp()
        
        var pos = position + caret_pos + Vector2(0, line_height)
        match font_size:
            0: pos.y += 40
            1: pos.y += 30
            2: pos.y += 16
            3: pos.y -= 75

        if pos.y > size.y-10: 
            pos = position + caret_pos + Vector2(0, -line_height)
            match font_size:
                0: pos.y += 12
                1: pos.y += 6
                2: pos.y += 2
                3: pos.y -= 4
        
        # 确保不会超出右边界
        var editor_width = size.x
        if pos.x + ime_display.size.x > editor_width:
            pos.x = editor_width - ime_display.size.x
            
        # 确保不会超出左边界
        if pos.x < 0: pos.x = 0
            
        ime_display.position = pos

func update_compose_position(nd):
    if !is_active: return
    await get_tree().process_frame
    var line_height = get_line_height()
    var ime_height = nd.size.y
    var caret_pos = _gfcp()
    var pos = position + caret_pos - Vector2(0, line_height) - Vector2(0, 30)
    nd.position = pos

func _on_gui_input(event):
    if !is_active: return
    if event is InputEventKey and event.pressed:
        if event.unicode:
            last_unicode = String.chr(event.unicode)
        last_key_name = event.as_text_keycode()
        is_single_letter = true
        skip_effect = false
        prints(Util.f_usec(), 'input: ', last_key_name, last_unicode, event.keycode, 'compose|', ime_state.last_compose, '|')
        
        if event.keycode == 0 or last_key_name == 'Unknown':
            is_ime_input = true
            # 记录输入序列
            if ime_state.first_input == "":
                ime_state.first_input = last_unicode
                ime_state.input_sequence = last_unicode
            else:
                ime_state.input_sequence += last_unicode
            # Windows/macOS: 在输入时就触发完成效果
            if Editor.is_macos or Editor.is_windows:
                # _handle_ime_finish()
                Util.delay('_ime_compose', 0.06, _handle_ime_finish)
        else:
            is_ime_input = false

func _physics_process(delta):
    _time_b += delta
    # _time_c += delta

    if shake > 0:
        shake -= delta
        position = Vector2(randf_range(-shake_intensity,shake_intensity), randf_range(-shake_intensity,shake_intensity))
    else:
        position = Vector2.ZERO

func _on_text_changed():
    if !is_active: return
    prints(Util.f_usec(), 'on text changed', last_unicode, last_key_name)

    var len_d = len(text) - len(last_text)
    var pos = _gfcp() 
    var cur_caret_line = get_caret_line()
    var cur_caret_col = get_caret_column()
    
    var is_text_updated = false
    if len_d < 0 and _time_b > TIME_BOOM_INTERVAL:
        var thing = Boom.instantiate()
        thing.position = pos
        thing.destroy = true
        thing.last_key = last_unicode
        thing.audio = effects.audio
        thing.blips = effects.particles
        add_child(thing)
        is_text_updated = true
        _time_b = 0.0
        _dc(abs(len_d)*3)
        if effects.shake:
            _ss(0.2, 12)
    else: # len_d == 0, it's changed by other words
        var thing = Blip.instantiate()
        thing.pitch_increase = pitch_increase
        pitch_increase += 1.0
        pitch_increase = min(pitch_increase, 999)
        thing.position = pos
        thing.destroy = true
        thing.audio = effects.audio
        thing.blips = effects.particles
        thing.last_key = last_unicode
        add_child(thing)
        is_text_updated = true
        _ic(len_d)
        if effects.shake:
            match font_size:
                # _ss(0.05, 6)
                0: _ss(0.04, 3)
                1: _ss(0.04, 4)
                2: _ss(0.05, 5)
                3: _ss(0.05, 6)

    if cur_caret_line != last_caret_line:
        if effects.newline:
            var thing = Newline.instantiate()
            thing.position = pos 
            thing.destroy = true
            thing.caret_col = cur_caret_col
            thing.last_key = last_unicode
            add_child(thing)

            _fc(pos)
        if effects.shake:
            _ss(0.08, 8)

        pitch_increase = 0.0
        is_text_updated = true
        last_caret_line = cur_caret_line

    if is_text_updated: last_text = text
    caret_line = cur_caret_line
    caret_column = cur_caret_col

func _on_caret_changed():
    caret_line = get_caret_line()
    caret_column = get_caret_column()
    prints(Util.f_usec(), 'caret_changed', caret_line, caret_column)
    ime_state.first_input = ""

func _gfcp():
    var cp = get_caret_draw_pos()
    var lh = get_line_height()
    var c_line = get_caret_line()
    var c_col = get_caret_column()
    if c_col == 0 and c_line != 0: cp.y += lh * 0.45
    cp += Vector2(0,-lh/2.0)
    return cp
# ---------------
func _ccnin():
    if combo_node == null or !is_instance_valid(combo_node):
        var thing = Combo.instantiate()
        add_child.call_deferred(thing)
        combo_node = thing

func _ic(n=1, delay=0):
    if delay: await get_tree().create_timer(delay).timeout
    if effects.combo:
        _ccnin()
        combo_node.incr(n)

func _dc(n=1):
    if effects.combo:
        if combo_node:
            combo_node.decr(n)
            if combo_node.count <= 0:
                _rc()

func _fc(pos):
    if effects.combo:
        if combo_node:
            var count = combo_node.combo_count
            prints('finish combo', count, effects.combo_shot, EffectLaser.can_finish_combo(count), last_key_name=='Enter', last_unicode, last_key_name)
            if effects.combo_shot and EffectLaser.can_finish_combo(count) and last_key_name == 'Enter':
                print('create laser')
                var thing = Laser.instantiate()
                thing.count = count
                thing.audio = effects.audio
                thing.position.y = pos.y + 3
                add_child(thing)
                if effects.shake:
                    var size = EffectLaser.get_count_size(count)
                    _ssf(EffectLaser.get_main_duration(count)-0.3, size * 3)
            combo_node.queue_free()
            combo_node = null

func _rc():
    pitch_increase = 0
    if effects.combo:
        if combo_node:
            combo_node.queue_free()
            combo_node = null

func _ss(duration, intensity):
    if shake > 0:
        return
        
    shake = duration
    shake_intensity = intensity
func _ssf(duration, intensity):
    shake = duration
    shake_intensity = intensity
# ---------------
func _notification(what):
    if what == NOTIFICATION_OS_IME_UPDATE:
        if !is_active: return
        var t = DisplayServer.ime_get_text()
        prints('[%d]' % Time.get_ticks_usec(), 'note ime update', is_ime_input, t)
        _feed_ime_compose(t)

func _on_ime_buffer_changed(buffer):
    if !is_active: return
    # _feed_ime_compose(buffer)
    _feed_ime_compose(ime.context.get_current_candidate())

class IMECompose extends ColorRect:
    var _label: AnimatedText = null
    var is_ready = false
    func _init():
        custom_minimum_size = Vector2(10, 10)
        # color = '336633'
        _label = AnimatedText.new()
        add_child(_label)

    func _ready():
        is_ready = true
        _label.text = text

    var text = ''
    func set_text(t:String):
        text = t
        if is_ready: _label.text = t

    func clear():
        text = ''
        if is_ready: _label.text = ''
    func finish_compose():
        if is_ready: _label.finish_compose()
    func cancel_compose():
        if is_ready: _label.cancel_compose()

func _feed_ime_compose(t: String):
    print('[%d]feed ime compose: %s' % [Time.get_ticks_usec(), t])

    
    var current_time = Time.get_ticks_msec()
    prints(Util.f_usec(), 'compose|%s|%s|' % [ime_state.last_compose, t], ime_state.last_compose.length(), t.length(), is_ime_input)
    # prints(Util.f_usec(), 'get state', ime_state)

    
    # 如果最近刚完成输入，忽略后续的空字符串通知
    if t.length() == 0 and current_time - ime_state.last_finish_time < 50:  # 50ms 阈值
        var id = ime_state.compose_id
        if _has_ime_compose(id):
            var m = _get_ime_compose(id)
            m.set_text(t)
            print('is just finished, ignore')
            push_error('set composed text with 0')
        return

    # we need a more intutive combo, that per each type

    var t_d = t.length() - ime_state.last_compose.length()
    prints('delta', t_d, t, ime_state.last_compose)
    if t_d > 0:
        _ic(t_d)
        _show_char_force(' ')
    elif t_d < 0:
        _dc(-t_d * 3)
        var pos = _gfcp()
        var thing = Boom.instantiate()
        thing.position = pos
        thing.destroy = true
        thing.audio = effects.audio
        thing.blips = effects.particles
        add_child.call_deferred(thing)
    
    # 开始新的输入
    if not ime_state.is_composing and t.length() != 0:
        ime_state.is_composing = true
        ime_state.pending_finish = false
        ime_state.pending_cancel = false
        ime_state.first_input = ""
        ime_state.input_sequence = ""  # 重置输入序列
        ime_state.compose_id = '%d|%d' % [caret_line, caret_column]
        print('start new compose', ime_state.compose_id)
        ime_state.last_compose = t
        ime_state.last_non_empty = t
        ime_state.last_update_time = current_time
        var m = _get_ime_compose(ime_state.compose_id)
        m.set_text(t)
    else:
        # 检测输入完成或取消
        if ime_state.last_compose.length() != 0 and t.length() == 0:
            if is_ime_input:
                # Linux: 在这里触发完成效果
                if Editor.is_linux:
                    _handle_ime_finish()
                ime_state.pending_finish = true
            else:
                _handle_ime_cancel()
                ime_state.pending_cancel = true
        else:
            ime_state.last_compose = t
            if t != "": ime_state.last_non_empty = t
            ime_state.last_update_time = current_time

            if t == '':
                if _has_ime_compose(ime_state.compose_id):
                    var m = _get_ime_compose(ime_state.compose_id)
                    m.set_text(t)
                    push_error('set composed text with 0')
                clear_compose()
            else:
                var m = _get_ime_compose(ime_state.compose_id)
                m.set_text(t)
                print('set ime compose text:', t, '|')
                if t == '新年快乐':
                    m._label.enable_rainbow = true
                else:
                    if m._label.enable_rainbow:
                        m._label.enable_rainbow = false


func _handle_ime_finish():
    prints(Util.f_usec(), '_handle_ime_finish', last_unicode, last_key_name, ime_state.last_non_empty)
    if not ime_state.pending_finish and ime_state.input_sequence != "":
        # 检查输入序列是否与 last_compose 匹配
        # This is only valid on linux
        # if ime_state.first_input != "" and ime_state.last_non_empty[0] != ime_state.first_input:
        #     _handle_ime_cancel()
        #     return
            
        prints(Util.f_usec(), 'finish ime compose', ime_state.last_compose, ime_state.last_non_empty, ime_state.input_sequence)
        # var m = _get_ime_compose()
        # m.position = Vector2.ZERO
        # m.finish_compose()

        # 在这里触发完成效果
        # var pos = _gfcp()
        # var thing = Blip.instantiate()
        # thing.position = pos
        # thing.destroy = true
        # thing.audio = effects.audio
        # thing.blips = effects.particles
        # thing.last_key = ime_state.input_sequence if ime_state.input_sequence != "" else ime_state.last_non_empty
        # add_child.call_deferred(thing)

        _show_multi_char(ime_state.input_sequence if ime_state.input_sequence != "" else ime_state.last_non_empty, false, {audio=false})
        
        # if effects.shake:
        #     _ss(0.08, 8)
        
        ime_state.last_compose = ""
        ime_state.last_non_empty = ""
        ime_state.is_composing = false
        ime_state.pending_finish = true
        ime_state.last_finish_time = Time.get_ticks_msec()
        ime_state.first_input = ""
        ime_state.input_sequence = ""  # 重置输入序列
        print('set state finish', ime_state)

        finish_compose()
    else:
        push_error('not finished?', ime_state)
        clear_compose()
    is_ime_input = false

func _handle_ime_cancel():
    if not ime_state.pending_cancel and not ime_state.pending_finish:
        prints(Util.f_usec(), 'cancel ime compose', ime_state.last_compose, ime_state.last_non_empty)
        # 在这里触发取消效果
        var pos = _gfcp()
        var thing = Boom.instantiate()
        thing.position = pos
        thing.destroy = true
        thing.audio = effects.audio
        thing.blips = effects.particles
        add_child.call_deferred(thing)
        
        if effects.shake:
            _ss(0.05, 6)
        
        ime_state.last_compose = ""
        ime_state.last_non_empty = ""
        ime_state.is_composing = false
        ime_state.pending_cancel = true
        ime_state.first_input = ""
        ime_state.input_sequence = ""  # 重置输入序列
        print('set state cancel', ime_state)
        cancel_compose()
    else:
        push_error('not canceld ?', ime_state)
        clear_compose()


func finish_compose():
    var id = ime_state.compose_id
    var m = _get_ime_compose(id)
    m.finish_compose()
    _free_ime_compose(id)

func cancel_compose():
    var id = ime_state.compose_id
    var m = _get_ime_compose(id)
    m.cancel_compose()
    _free_ime_compose(id)

func clear_compose():
    push_warning('CLEAR COMPOSE')
    for id in compose_nodes:
        _free_ime_compose(id)

# -----------------------
func _otc():
    if !is_active: return
    prints(Util.f_usec(), 'fill with otc', last_unicode, last_key_name)
    if skip_effect:return
    var o=caret_line
    var p=caret_column
    caret_line=get_caret_line()
    caret_column=get_caret_column()
    last_line=get_line(caret_line)
    if last_key_name == '(Unset)':
        if caret_line==o:
            is_single_letter=false
            var _last = last_line.substr(p,caret_column-p)
            _show_multi_char(_last)
            _incr_multi_combo(_last)
            # emit_signal('typing')
            # update_editor_stats()
            last_unicode=''
        skip_effect=true

func feed_ime_input(key):
    if !is_active: return
    prints(Util.f_usec(), 'handle tiny ime', last_unicode, last_key_name, key)
    skip_effect = true
    last_unicode = ''

    insert_text_at_caret(key)

    # await get_tree().process_frame
    # _show_multi_char(key)
    # _incr_multi_combo(key)

    
    ime_state.pending_finish = false
    ime_state.input_sequence = key
    _handle_ime_finish()
    ime_state.pending_finish = true

    # emit_signal('typing')
    # update_editor_stats()

func _incr_multi_combo(s, mul=3):
    var n = s.length()
    var t = 0.22 + (0.28 if n > 7 else n * 0.04)
    var i = 0
    for k in s:
        _ic(1 if _is_ascii(k) else mul, t * i / n)
        i += 1

func _show_multi_char(s: String, f: bool = false, params = {}) -> void:
    var l = s.length()
    var t = 0.22 + (0.28 if l > 7 else l * 0.04)
    var h = get_line_height() * 0.25
    var x = 0.0
    var o = []
    for c in s: x += h * (2 if c.unicode_at(0) > 127 else 1); o.append(x)
    var p = get_caret_draw_pos() + Vector2(0, -get_line_height()/2.0) + Vector2(x, 0) if f else Vector2.ZERO
    for i in l: _show_char_force(s[i], t * i / l, -x + o[i], p, params)

func _show_char_force(t, d=0.0, x=0, p=Vector2.ZERO, params={}):
    await get_tree().process_frame
    if p == Vector2.ZERO:
        var line_height = get_line_height()
        p = get_caret_draw_pos() + Vector2(0,-line_height/2.0)
    if params.has('position'): p = params.position
    if d: await get_tree().create_timer(d).timeout
    
    if effects.chars: 
        var thing = Blip.instantiate()
        thing.pitch_increase = pitch_increase
        pitch_increase += 1.0
        pitch_increase = min(pitch_increase, 999)
        thing.position = p
        thing.char_offset = Vector2(x, 0)
        thing.destroy = true
        if d:
            thing.audio = params.get('audio', effects.audio)
            thing.blips = false
        else:
            thing.audio = params.get('audio', effects.audio)
            thing.blips = params.get('particles', effects.particles)
        thing.last_key = t
        add_child(thing)
    
    if effects.shake: 
        match font_size:
            0: _ss(0.04, 3)
            1: _ss(0.04, 4)
            2: _ss(0.05, 5)
            3: _ss(0.05, 6)
        
func _is_ascii(c):
    return c.unicode_at(0) <= 127

# ----------------------------

