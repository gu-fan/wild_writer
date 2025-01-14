class_name WildEdit
extends CodeEdit

# TODO
# FIXED 当输入input的时候，应该清掉之前的ime_compose,有时会残留 (when reset ime, clear compose)
# FIXED 当使用gfcp的时候，如果是TinyIME，其在0 col时位置会上移半格，OS IME则正常 (not used gfcp)
# ?ime compose bonus使用glitch text. seems not 
# FIXED is delete (incr_error) duplicated?
# DONE line number gutter
# DONE on_text_changed: Ctrl+V should consider Command+V
# FIXED Option key in Key Capture (Option seems is Alt)
# DONE Big Boom for big delete
# DONE laser effect
# DONE animated text anim fix
# settings
# font
# rating final


# Input Process Direction
# KEY_PRESSED -> gui_input -> text_changed
# OS IME 
#   KEY_PRESSED(NA) -> OS IME UPDATE
# OS IME FINISH
#   KEY_PRESSED(NA) -> OS IME UPDATE ( prev 1, curr 0, wait finish or cancel ) -> gui_input got input sequence of unicode -> FINISH COMPOSE -> text_changed
# OS IME CANCEL
#   KEY_PRESSED(NA) -> OS IME UPDATE ( prev 1, curr 0, wait finish or cancel ) -> after wait, no gui input handle finish compose -> CANCEL COMPOSE -> text_changed
# OS IME PARTIAL
#   KEY_PRESSED(NA) -> OS IME UPDATE -> check the cjk_len to consider is partial -> skip the delete effect
# TINY IME
# KEY_PRESSED -> TINY IME UPDATE -> BUFFER/CANDIDATE CHANGED -> IME COMPOSE

# CHECKLIST of TYPE AND IME COMPOSE
# 1. speed type:
#    english
#      keys OK
#      word OK
#      delete OK
#      sentence style OK
#      Ctrl+C/V/Z/Y OK
#    chinese
#      keys OK
#      word OK
#      delete OK
#      sentence style OK
#      Ctrl+C/V/Z/Y Ok
# 2. ime compose
#    OS ime
#      start   Ok
#      finish  OK
#      cancel  OK
#      delete  OK
#      partial update (XXX: this is not reconginzed now, and will trigger as delete in compose) (FIXED)
#      change caret pos   (this will keep the os ime and ime compose , but seems same behavior, so not fix)
#      start motions etc (will remove)
#      refocus window (will apply)
#    Tiny ime
#      start  OK
#      finish  OK
#      cancel  OK
#      delete  OK
#      partial update OK
#      change caret pos  (this can keep the origin compose, and follow the ime_display, seems ok)
#      start motions etc (can keep)
#      refocus window (can keep)
# 3. special symbols
# 4. emojis (next version)

var is_active = false

const Boom: PackedScene    = preload("res://effects/boom.tscn")
const BoomBig: PackedScene    = preload("res://effects/boom_big.tscn")
const Combo: PackedScene   = preload("res://effects/combo.tscn")
const Laser: PackedScene   = preload("res://effects/laser.tscn")
const Blip: PackedScene    = preload("res://effects/blip.tscn")
const Newline: PackedScene = preload("res://effects/newline.tscn")
const Dust: PackedScene    = preload("res://effects/dust.tscn")
const PackedFireworkProjectile: PackedScene = preload("res://effects/firework_projectile.tscn")

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
var last_caret_line: = 0  # the last caret line pos
var caret_pos := Vector2.ZERO
var last_caret_pos: = Vector2.ZERO

var is_mod_key = false
var last_line: String = ''
var last_unicode: String = ''
var last_key_name: String = ''
var last_text: String = ''
var last_caret_newline: = 0  # to detect if it's a newline
var pre_key_name : String = ''
var pre_unicode : String = ''

const TIME_BOOM_INTERVAL = 0.1
const TIME_CHAR_INTERVAL = 0.1
var _time_b: float = 0.0
# var _time_c: float = 0.0
var font_size := 0 # the setting in basic


var ime
var ime_display

var skip_effect = false
var is_single_letter = false

var is_ime_input = false   # 认为该key input 是 ime的输入

var ime_state = {
    compose_id = "",
    is_composing = false,      # 是否正在输入中
    last_compose = "",         # 上一次的混合文本
    last_compose_alt = "",         # 上一次的混合文本
    last_non_empty = "",       # 上一次非空的混合文本
    pending_finish = false,    # 是否有待处理的完成事件
    pending_cancel = false,    # 是否有待处理的取消事件
    last_update_time = 0,      # 最后更新时间
    last_finish_time = 0,      # 最后完成时间
    first_input = "",          # 输入序列的第一个字符
    input_sequence = "",       # 完整的输入序列
    last_os_ime_compose = "",
    curr_tiny_ime_buffer = "",
    last_tiny_ime_buffer = "",
}


var combo_node: Control
var compose_nodes : = {}
# var compose_node_pool :  = []
# var compose_node_pool_size := 4

func _ready():

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
            clear_compose()
    )
    caret_changed.connect(update_ime_position)
    # caret_changed.connect(update_compose_position)

    ime.ime_buffer_changed.connect(_on_ime_buffer_changed)

    await get_tree().process_frame
    _init_gutter()

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
            is_mod_key = false
            pre_unicode = last_unicode
        else:
            last_unicode = ''
            is_mod_key = true
        last_key_name = event.as_text_keycode()
        is_single_letter = true
        skip_effect = false
        prints(Util.f_msec(), 'INPUT:', last_key_name, last_unicode, event.keycode, 'compose|', ime_state.last_compose, '|', event.as_text_key_label(),event.as_text_physical_keycode() )

        # XXX:
        # some key is not repeating 
        # if last_key_name in '1234567890FJQPXVBM' and is_mod_key:
        if last_key_name in '1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ' and is_mod_key and event.echo:
            # print('insert echo f/j ??')
            insert_text_at_caret(pre_unicode)

        elif last_key_name in ['Space', 'Enter'] and pre_key_name not in ['Space', 'Enter']:
            Editor.creative_mode.incr_word()
        # if last_key_name == 'Delete' or last_key_name == 'Backspace':
        #     clear_compose()
        #     Editor.creative_mode.incr_error()
        elif last_key_name in ['Ctrl+X', 'Cmd+X', 'Command+X']:
            last_text = text
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
            skip_effect = true
        elif last_key_name in ['Ctrl+Z', 'Cmd+Z', 'Command+Z']:
            last_text = text
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
            skip_effect = true
        elif last_key_name in ['Ctrl+Y', 'Cmd+Y', 'Command+Y']:
            last_text = text
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
            skip_effect = true
        elif last_key_name in ['Ctrl+C', 'Cmd+C', 'Command+C']:
            _show_char_force(last_key_name)
            Editor.creative_mode.incr_key()
            skip_effect = true
        elif last_key_name in ['Ctrl+V', 'Cmd+V', 'Command+V']:
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
            last_text = text
            skip_effect = true
        elif last_key_name in ['Ctrl+D', 'Cmd+D', 'Command+D']:
            set_caret_line(caret_line+10)
            skip_effect = true
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
        elif last_key_name in ['Ctrl+U', 'Cmd+U', 'Command+U']:
            set_caret_line(caret_line-10)
            skip_effect = true
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
        elif last_key_name in ['Ctrl+J', 'Cmd+J', 'Command+J']:
            set_caret_line(caret_line+1)
            skip_effect = true
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
        elif last_key_name in ['Ctrl+K', 'Cmd+K', 'Command+K']:
            set_caret_line(caret_line-1)
            skip_effect = true
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
        elif last_key_name in ['Ctrl+H', 'Cmd+H', 'Command+H']:
            set_caret_column(caret_column-1)
            skip_effect = true
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
        elif last_key_name in ['Ctrl+L', 'Cmd+L', 'Command+L']:
            set_caret_column(caret_column+1)
            skip_effect = true
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
        elif last_key_name in ['Up', 'Down', 'Right', 'Left']:
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
            skip_effect = true
        elif last_key_name in ['Ctrl+A', 'Cmd+A', 'Command+A']:
            Editor.creative_mode.incr_key()
            _show_char_force(last_key_name)
            skip_effect = true

        if event.keycode == 0 or last_key_name == 'Unknown':
            # XXX: 
            # on macOS, pressing multi key in same time will emit (Unset) and keycode 0, like 'jk'
            # check unicode to ignore it
            if !_is_ascii(last_unicode):
                is_ime_input = true
                # 记录输入序列
                if ime_state.first_input == "":
                    ime_state.first_input = last_unicode
                    ime_state.input_sequence = last_unicode
                else:
                    ime_state.input_sequence += last_unicode
                print('len |', last_unicode, '|', last_unicode.length())
                # NOW DELAY ALL OS, and OS IME UPDATE WAIT CANCEL IS DELAYED TOO
                # 0.04 (try_handle_finish)
                # 0.07 (_wait_ime_cancel_or_finish)
                # TWO SEQUENCE ON DIFFERENT OS WILL BOTH BE HANDLED
                # A.
                # 0 -> 0.04 try handle
                # 0.01 -->  0.08 wait ime cancel
                # B.
                # 0 -->  0.07 wait ime cancel
                # 0.01 -> 0.05 try handle

                ime_state.pending_finish = true
                Util.delay('_ime_compose', 0.04, _handle_ime_finish)
            else:
                is_ime_input = false
        else:
            is_ime_input = false

        pre_key_name = last_key_name

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
    if skip_effect:
        last_text = text
        return
    prints(Util.f_msec(), 'on text changed', last_unicode, last_key_name)

    var len_d = len(text) - len(last_text)
    var pos = _gfcp() 
    var cur_caret_line = get_caret_line()
    var cur_caret_col = get_caret_column()

    # Editor.creative_mode.incr_key(len_d)
    # Editor.creative_mode.update_stats(len_d, true)

    # var current_text = get_line(get_caret_line())
    # var is_word_complete = false
    # if last_unicode in [" ", ".", ",", "!", "?", ";", ":", "\n"]:
    #     is_word_complete = true
    # Editor.creative_mode.update_style_stats(current_text, is_word_complete)
    var is_text_updated = false
    if len_d < 0 and _time_b > TIME_BOOM_INTERVAL:
        is_text_updated = true
        _dc(abs(len_d)*3)
        _show_boom_extra(len_d)
    elif len_d > 0: # len_d == 0, it's changed by other words
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
        Editor.creative_mode.incr_key()
        _ic(len_d)
        if effects.shake:
            match font_size:
                # _ss(0.05, 6)
                0: _ss(0.04, 3)
                1: _ss(0.04, 4)
                2: _ss(0.05, 5)
                3: _ss(0.05, 6)

    if cur_caret_line != last_caret_newline:
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

        last_line = get_line(last_caret_line)
        Editor.creative_mode.update_combo(last_line)
        print('last_line', last_line)

        pitch_increase = 0.0
        is_text_updated = true
        last_caret_newline = cur_caret_line
        clear_compose()

    if is_text_updated: last_text = text
    caret_line = cur_caret_line
    caret_column = cur_caret_col
    prints('TEXT CHANGED updated', is_text_updated, last_unicode, len_d)
    update_gutter()


func _on_caret_changed():
    last_caret_line = caret_line
    last_caret_pos = caret_pos
    caret_line = get_caret_line()
    caret_column = get_caret_column()
    caret_pos = _gfcp()
    prints(Util.f_msec(), 'caret_changed', caret_line, caret_column, caret_pos)
    ime_state.first_input = ""

func _gfcp():
    var cp = get_caret_draw_pos()
    var lh = get_line_height()
    var c_line = get_caret_line()
    var c_col = get_caret_column()
    # if c_col == 0 and c_line != 0: cp.y += lh * 0.45
    if c_col == 0: cp.y += lh * 0.45
    cp += Vector2(0,-lh/2.0)
    return cp
# ---------------
func _ccnin():
    if combo_node == null or !is_instance_valid(combo_node):
        var thing = Combo.instantiate()
        add_child.call_deferred(thing)
        combo_node = thing
        if _is_combo_rating_shown: 
            combo_node.modulate.a = 0.0


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
            TwnLite.at(combo_node).tween({prop='modulate:a', to=0.0, dur=0.3}).callee(combo_node.queue_free)
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
var _is_combo_rating_shown = false
func _on_combo_rating_vis_changed(v):
    _is_combo_rating_shown = v
    if v:
        if combo_node: combo_node.modulate.a = 0.0
    else:
        if combo_node: 
            TwnLite.at(combo_node).tween({
                prop='modulate:a',
                from = 0.0,
                to = 1.0,
                dur= 0.2,
            })

# ---------------
func _notification(what):
    if what == NOTIFICATION_OS_IME_UPDATE:
        if !is_active: return
        var t = DisplayServer.ime_get_text()
        prints(Util.f_msec(), 'OS IME UPDATE', is_ime_input, t)
        if t == "" and ime_state.last_os_ime_compose == "":  # macOS always feed empty update
            ime_state.last_os_ime_compose = t
            return
        # is_feed_by_os_ime = true
        ime_state.last_os_ime_compose = t
        ime_state.is_composing = true  # make it always true, so it can be canceld when is_feed_empty
        _feed_ime_compose(t, true)

func _on_ime_buffer_changed(buffer, is_partial_feed=false):
    if !is_active: return
    # _feed_ime_compose(buffer)
    # XXX:
    # there is another problem, that when partial feed candidate
    # should not consider the delta
    prints(Util.f_msec(), 'TINY IME UPDATE', is_ime_input, buffer)
    # is_feed_by_os_ime = false
    ime_state.is_partial_feed = is_partial_feed
    ime_state.curr_tiny_ime_buffer = buffer
    # if buffer.length() == 0: ime_state.is_composing = false
    ime_state.is_composing = true  # make it always true, so it can be canceld when is_feed_empty
    _feed_ime_compose(ime.context.get_current_candidate(), false)
    ime_state.last_tiny_ime_buffer = buffer

class IMECompose extends ColorRect:
    var _label: AnimatedText = null
    var is_ready = false
    func _init():
        custom_minimum_size = Vector2(10, 10)
        # color = '336633'
        _label = AnimatedText.new()
        add_child(_label)
        _label.position = Vector2(0, -10)

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

func _feed_ime_compose(t: String, is_feed_by_os_ime: bool):
    print(Util.f_msec(), 'feed ime compose: %s' % [t])
    
    var current_time = Time.get_ticks_msec()
    prints(Util.f_msec(), 'compose|%s|%s|' % [ime_state.last_compose, t], ime_state.last_compose.length(), t.length(), is_ime_input)
    # prints(Util.f_msec(), 'get state', ime_state)
    
    # # 如果最近刚完成输入，忽略后续的空字符串通知
    # if t.length() == 0 and current_time - ime_state.last_finish_time < 50:  # 50ms 阈值
    #     var id = ime_state.compose_id
    #     if _has_ime_compose(id):
    #         var m = _get_ime_compose(id)
    #         m.set_text(t)
    #         print('just finished compose, ignore')
    #         push_error('set composed text with 0')
    #     return

    # we need a more intutive combo, that per each type
    var _alt_t = t.replace(' ', '').replace('\'', '')
    var t_d = _get_delta_len(_alt_t, ime_state.last_compose_alt)
    prints('got alt len', _alt_t, t_d)

    var is_feed_empty = false
    if t.length() == 0:
        is_feed_empty = true

    # for tiny ime, handle by buffer len, not candidate len
    if !is_feed_by_os_ime:
        if ime_state.is_partial_feed: # ignore partial feed ones
            t_d = 0
        else:
            var last_buf_len = ime_state.last_tiny_ime_buffer.length()
            var curr_buf_len = ime_state.curr_tiny_ime_buffer.length()
            t_d = curr_buf_len - last_buf_len
            print('got tiny delta', t_d)
            if curr_buf_len != 0: 
                is_feed_empty = false
            else:
                is_feed_empty = true
    else:
        if t_d < 0:
            # this is partial feed of OS IME
            if _get_cjk_len(_alt_t) > _get_cjk_len(ime_state.last_compose_alt):
                t_d = 0
                print('got partial feed of OS IME')

    prints('got t_d', t.length(), t_d, is_feed_empty, '|', ime_state.last_compose, '|', t, '|', is_feed_by_os_ime)
    
    # Trigger the delta VFX
    _trigger_ime_compose_effect(t_d, is_feed_empty, is_feed_by_os_ime)
    
    # 开始新的输入
    if not ime_state.is_composing and t.length() == 0:
        # XXX: not runing here
        push_error(' create new ???? ')
        ime_state.is_composing = true
        ime_state.last_compose_alt = ""
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
        is_ime_input = false # ?? fix the error of ime_input reset?
    else:
        # 检测输入完成或取消
        if ime_state.last_compose.length() != 0 and is_feed_empty:
            if is_ime_input: # XXX: this is errorness, here, as it's not reset after last ime
                # Linux: 在这里触发完成效果
                ime_state.pending_finish = true
                # if Editor.is_linux: _handle_ime_finish()
            else:
                ime_state.pending_cancel = true
                # _handle_ime_cancel()
                _wait_ime_cancel_or_finish()

    prints('set last compose', ime_state, is_feed_empty)

    ime_state.last_compose = t
    ime_state.last_compose_alt = _alt_t
    if t != "": ime_state.last_non_empty = t
    ime_state.last_update_time = current_time

    if is_feed_empty:
        if _has_ime_compose(ime_state.compose_id):
            var m = _get_ime_compose(ime_state.compose_id)
            m.set_text(t)
            push_error('set prev composed text to 0')
        clear_compose()
    else:
        var m = _get_ime_compose(ime_state.compose_id)
        m.set_text(_alt_t)
        print('set ime compose text:', t, '|')
        if t in ['新年快乐', '万事如意']:
            m._label.enable_rainbow = true
        else:
            if m._label.enable_rainbow:
                m._label.enable_rainbow = false


func _handle_ime_finish():
    prints(Util.f_msec(), '_handle_ime_finish', last_unicode, last_key_name, ime_state.last_non_empty, ime_state.input_sequence)
    if ime_state.pending_finish and ime_state.input_sequence != "":
        # 检查输入序列是否与 last_compose 匹配
        # This is only valid on linux
        # if ime_state.first_input != "" and ime_state.last_non_empty[0] != ime_state.first_input:
        #     _handle_ime_cancel()
        #     return
            
        prints(Util.f_msec(), 'finish ime compose', ime_state.last_compose, ime_state.last_non_empty, ime_state.input_sequence)
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

        # _show_multi_char(ime_state.input_sequence if ime_state.input_sequence != "" else ime_state.last_non_empty, false, {audio=false})
        _show_multi_char(ime_state.input_sequence if ime_state.input_sequence != "" else ime_state.last_non_empty, false)
        # note: we should split the word with 
        var word_len = Editor.creative_mode.get_paragraph_word_length_cjk(ime_state.input_sequence)
        prints('got word len', word_len, ime_state.input_sequence)
        Editor.creative_mode.incr_word(word_len)
        
        # if effects.shake:
        #     _ss(0.08, 8)

        if ime_state.input_sequence in ['新年快乐', '万事如意']:
            start_fireworks(ime_state.input_sequence)
        
        ime_state.last_compose = ""
        ime_state.last_compose_alt = ""
        ime_state.last_non_empty = ""
        ime_state.is_composing = false
        ime_state.pending_finish = false
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
    prints(Util.f_msec(), 'cancel ime compose', ime_state.last_compose, ime_state.last_non_empty)
    if ime_state.pending_cancel and ime_state.last_non_empty:
        # 在这里触发取消效果
        var pos = _gfcp()
        var thing = Dust.instantiate()
        thing.position = pos
        thing.destroy = true
        thing.audio = effects.audio
        thing.blips = effects.particles
        add_child.call_deferred(thing)
        
        if effects.shake: _ss(0.05, 6)

        Editor.creative_mode.incr_error()
        
        ime_state.last_compose = ""
        ime_state.last_compose_alt = ""
        ime_state.last_non_empty = ""
        ime_state.is_composing = false
        ime_state.pending_cancel = false
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
    for id in compose_nodes:
        _free_ime_compose(id)

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
        push_error('try to free invalid id', id)

func _has_ime_compose(id=''):
    return compose_nodes.has(id)

# -----------------------
func _otc():
    if !is_active: return
    if skip_effect:return
    var o=caret_line
    var p=caret_column
    print(Util.f_msec(), 'OTC char', last_key_name)
    caret_line=get_caret_line()
    caret_column=get_caret_column()
    last_line=get_line(caret_line)
    if last_key_name == '(Unset)':
        if caret_line==o:
            is_single_letter=false
            var _last = last_line.substr(p,caret_column-p)
            # _show_multi_char(_last)
            # _incr_multi_combo(_last)
            print('OTC captured, not print now', _last)
            # emit_signal('typing')
            # update_editor_stats()
            last_unicode=''
        skip_effect=true

func feed_ime_input(key):
    if !is_active: return
    prints(Util.f_msec(), 'handle tiny ime', last_unicode, last_key_name, key)
    skip_effect = true
    last_unicode = ''

    insert_text_at_caret(key)

    # await get_tree().process_frame
    # _show_multi_char(key)
    # _incr_multi_combo(key)

    ime_state.pending_finish = true
    ime_state.input_sequence = key
    _handle_ime_finish()

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
    # var p = get_caret_draw_pos() + Vector2(0, -get_line_height()/2.0) + Vector2(x, 0) if f else Vector2.ZERO
    var p = _gfcp() + Vector2(x, 0) if f else Vector2.ZERO
    for i in l: _show_char_force(s[i], t * i / l, -x + o[i], p, params)

func _show_char_force(t, d=0.0, x=0, p=Vector2.ZERO, params={}):
    await get_tree().process_frame
    if p == Vector2.ZERO:
        var line_height = get_line_height()
        # p = get_caret_draw_pos() + Vector2(0,-line_height/2.0)
        p = _gfcp()
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
            # thing.audio = params.get('audio', effects.audio)
            thing.audio = false
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
    if c.is_empty(): return true
    # return c.unicode_at(0) <= 127
    return c.unicode_at(0) <= 0x3000
func _is_cjk(c):
    if c.is_empty(): return false
    var v = c.unicode_at(0)
    return v >= 0x3000 and v <= 0x9FFF
    # return v >= 0x4E00 and v <= 0x9FFF
func _is_emoji(c):
    var v = c.unicode_at(0)
    return v >= 0x1F600 and v <= 0x1FFFF
func _get_w_len(s: String) -> int:
    var length := 0
    for c in s:
        if c.unicode_at(0) <= 0x3000:
            length += 1
        else:
            length += 2
    return length
func _get_delta_len(s1, s2):
    return _get_w_len(s1) - _get_w_len(s2)
func _get_cjk_len(s: String):
    var length := 0
    for c in s:
        if c.unicode_at(0) > 0x3000:
            length += 1
    return length

# ----------------------------
func start_fireworks(chars:String):
    # 获取视口中心位置
    var viewport_size = get_viewport_rect().size
    var center_x = viewport_size.x / 2
    var center_y = viewport_size.y / 2
    
    # 计算字符总宽度，以便居中排列
    var total_chars = chars.length()
    var char_spacing = 200  # 字符间距
    var total_width = total_chars * char_spacing
    var start_x = center_x - (total_width / 2)

    var pos = _gfcp()
    for i in chars.length():
        var config = {
                'from': Vector2(pos.x, 0) + Vector2(i * 100 -200 + Rnd.rangef(-50, 50) , size.y + 100) ,
                'to': Vector2(
                    start_x + i * char_spacing + Rnd.rangef(-50, 50),  # 目标x与起始x相同
                    center_y - 200  + Rnd.rangef(-50, 50)              # 在中心上方爆炸
                ),
                'delay': Rnd.rangef(-0.1, 0.1) + i * 0.15,
                'char' : chars[i],
                'color' : Color.from_hsv(0.2 + Rnd.rangef(0.4), 0.8, 1.0),
            }
        _launch_firework(config)
    await Util.wait(1)
    Editor.view.firework.start_drops()
    # Editor.view.firework.start_spray()
    await Util.wait(1)
    Editor.view.firework.stop_drops()
    # Editor.view.firework.stop_spray()
func _launch_firework(config):
    var delay = config.get('delay', 0)
    print('get delay', delay)
    # if delay: await get_tree().create_timer(delay)
    await Util.wait(delay)
    var projectile = FireworkProjectile.create(
        PackedFireworkProjectile,
        config.from,
        config.to,
        config.get("color", Color.WHITE),
        config.get('char', ''),
    )
    add_child(projectile)

# -----------------------------------
# handle the pending feed of ime
func _wait_ime_cancel_or_finish():
    Util.delay('_ime_wait', 0.07, __wait_ime_cancel_or_finish)

func __wait_ime_cancel_or_finish():
    var current_time = Time.get_ticks_msec()
    if current_time - ime_state.last_finish_time < 70:
        print('has just finished compose')
    else:
        print('not finished, will cancel compose')
        ime_state.pending_cancel = true
        _handle_ime_cancel()

func _trigger_ime_compose_effect(t_d, is_feed_empty, is_feed_by_os_ime):
    if t_d >= 0:
        Editor.creative_mode.incr_key()
        if t_d > 0: _ic(t_d)
        else: _ic(1)
        _show_char_force(' ')
    elif t_d < 0:
        # FOR MACOS, we should delay the boom to check if it's finished or not
        # if is_feed_by_os_ime and is_feed_empty: return
        # NOTE: if is_feed_empty for tiny ime, it will use cancel, not go down.
        if is_feed_empty: return
        Editor.creative_mode.incr_error()
        _dc(-t_d * 2)
        var pos = _gfcp()
        var thing = Dust.instantiate()
        thing.position = pos
        thing.destroy = true
        thing.audio = effects.audio
        thing.blips = effects.particles
        add_child.call_deferred(thing)


# -----------------

func _show_boom_extra(delta=0):
    await get_tree().process_frame
    _time_b = 0.0
    if effects.shake: _ss(0.2, 12)
    Editor.creative_mode.incr_error()
    prints('incr error', 1, 'text changed', caret_pos, last_caret_pos, delta)
    var thing
    var has_explode = false
    if abs(delta) > 10:
        if abs(caret_pos.y - last_caret_pos.y) > 100:
            thing = BoomBig.instantiate()
            thing.position = (last_caret_pos + caret_pos) / 2.0
            thing.destroy = true
            thing.last_key = ''
            thing.audio = effects.audio
            thing.blips = effects.particles
            # thing.scale = Vector2.ONE
            thing.animation = '2'
            thing.particle_scale = 2
            thing.sprite_scale = 2
            add_child(thing)
            has_explode = true
        # elif abs(caret_pos.x - last_caret_pos.x) > 100:
        #     thing = Boom.instantiate()
        #     thing.position =  (last_caret_pos + caret_pos) / 2.0
        #     thing.destroy = true
        #     thing.last_key = ''
        #     thing.audio = effects.audio
        #     thing.blips = effects.particles
        #     thing.sprite_scale = 1.5
        #     thing.particle_scale = 1.5
        #     # thing.scale.x = 2.0
        #     add_child(thing)
        #     has_explode = true

    if not has_explode:
        thing = Boom.instantiate()
        thing.position = caret_pos
        thing.destroy = true
        if is_mod_key:
            thing.last_key = last_key_name
        else:
            thing.last_key = last_unicode
        thing.audio = effects.audio
        thing.blips = effects.particles
        add_child(thing)

# ---------------------
var gutter_index_line = 0
func _init_gutter():
    # print('====== init gutter ======')
    gutter_index_line = get_gutter_count()
    add_gutter(gutter_index_line)
    # for i in c:
    #     var n = get_gutter_name(i)
    #     if n == 'line_numbers':
    #         gutter_index_line = i

    set_gutter_type(gutter_index_line, TextEdit.GUTTER_TYPE_STRING)
    update_gutter()

var _line_number_setted = 1
const SIZE_GUTTER_W = {
    0: 20,
    1: 20,
    2: 25,
    3: 50,
}
func update_gutter():
    var line_count = get_line_count()
    var len = str(line_count).length()
    var font_size = Editor.config.get_basic_setting("font_size")
    var gutter_size = SIZE_GUTTER_W[font_size]
    set_gutter_width(gutter_index_line, max(4*gutter_size, (len+1)*gutter_size))
    if Editor.config.get_basic_setting('line_number'):
        for line in get_line_count():
            var t = '%4d' % [line+1]
            if get_line_gutter_text(line, gutter_index_line ) != t:
                set_line_gutter_text(line, gutter_index_line, t)
                set_line_gutter_item_color(line, gutter_index_line, '666666')
        _line_number_setted = 1
    else:
        if _line_number_setted:
            for line in get_line_count():
                set_line_gutter_text(line, gutter_index_line, '')
            _line_number_setted = 0

# ---------------------
