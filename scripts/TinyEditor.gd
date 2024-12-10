class_name TinyEditor
extends CanvasLayer

signal typing

@onready var ime = TinyIME
@onready var editor: TextEdit = $Control/MarginContainer/VBoxContainer/TextEdit
# @onready var dock: Control = $Control/MarginContainer/VBoxContainer/Dock

const Boom: PackedScene = preload("res://effects/boom.tscn")
const Combo: PackedScene = preload("res://effects/combo.tscn")
const Laser: PackedScene = preload("res://effects/laser.tscn")
const Blip: PackedScene = preload("res://effects/blip.tscn")
const Newline: PackedScene = preload("res://effects/newline.tscn")
# const Dock: PackedScene = preload("res://scenes/dock.tscn")

const PITCH_DECREMENT := 2.0

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
var timer: float = 0.0
var last_key: String = ""
var pitch_increase: float = 0.0
var editors = {}

var combo_node: Control

var ime_display
var ime_button
var setting_button
var bottom_label
var editor_main
var font_size = 0 # the setting in basic

func init():

    editor_main = get_tree().current_scene

    ime_display = preload("res://scenes/ime_display.tscn").instantiate()
    ime_display.hide()
    add_child(ime_display)

    ime_display.feed_ime_input.connect(feed_ime_input)
    ime_button.pressed.connect(ime.toggle_ime)
    ime.ime_state_changed.connect(func(v):
        if v:
            ime_button.text = 'CN'
            ime_display.show()
            update_ime_position()
        else:
            ime_button.text = 'EN'
            ime_display.hide()
    )

    editor.caret_changed.connect(update_ime_position)
    setup_editor([editor])
    # typing.connect(Callable(dock,"_on_typing"))


func update_ime_position():
    if ime_display and ime_display.visible:
        var caret_pos = editor.get_caret_draw_pos()
        var line_height = editor.get_line_height()
        var ime_height = ime_display.size.y
        
        var pos = editor.position + caret_pos + Vector2(0, -line_height)
        match font_size:
            0: pos.y += 3
            1: pos.y -= 6
            2: pos.y -= 10
            3: pos.y -= 14
        
        # 如果位置会导致 IME 超出顶部，则将其放在光标下方
        if pos.y < -15: 
            pos.y = editor.position.y + caret_pos.y + line_height
            match font_size:
                0: pos.y += 38
                1: pos.y += 45
                2: pos.y += 50
                3: pos.y += 55
            
        # 确保不会超出右边界
        var editor_width = editor.size.x
        if pos.x + ime_display.size.x > editor_width:
            pos.x = editor_width - ime_display.size.x
            
        # 确保不会超出左边界
        if pos.x < 0: pos.x = 0
            
        ime_display.position = pos

func setup_editor(nodes):
    for child in nodes:
        if child is TextEdit:
            editors[child] = { 
                "text": child.text, 
                "line": child.get_caret_line() 
            }
            
            if child.caret_changed.is_connected(caret_changed):
                child.caret_changed.disconnect(caret_changed)
            child.caret_changed.connect(caret_changed.bind(child))
            
            if child.text_changed.is_connected(text_changed):
                child.text_changed.disconnect(text_changed)
            child.text_changed.connect(_on_text_changed)
            child.text_changed.connect(text_changed.bind(child))
            
            if child.gui_input.is_connected(gui_input):
                child.gui_input.disconnect(gui_input)
            child.gui_input.connect(gui_input)

func gui_input(event):
    # Get last key typed
    if event is InputEventKey and event.pressed:
        event = event as InputEventKey
        last_key = OS.get_keycode_string(event.get_keycode_with_modifiers())
        is_single_letter = true
        skip_effect = false
        if SettingManager.is_match_shortcut(last_key, 'ime', 'switch_key'):
            ime.toggle_ime()
            get_viewport().set_input_as_handled()
        elif last_key.to_lower() in ['up', 'down', 'right', 'left']:
            _scf(last_key)
        elif SettingManager.is_match_key(last_key, 'Ctrl+C'):
            var selected = editor.get_selected_text()
            DisplayServer.clipboard_set(selected)
            if OS.get_name() == 'Linux':
                DisplayServer.clipboard_set_primary(selected)
            _scf(last_key)
            get_viewport().set_input_as_handled()
        elif SettingManager.is_match_key(last_key, 'Ctrl+X'):
            var selected = editor.get_selected_text()
            DisplayServer.clipboard_set(selected)
            if OS.get_name() == 'Linux':
                DisplayServer.clipboard_set_primary(selected)
            _scf(last_key)
            editor.backspace()
            get_viewport().set_input_as_handled()
        elif SettingManager.is_match_key(last_key, 'Ctrl+A'):
            editor.select_all()
            _scf(last_key)
            get_viewport().set_input_as_handled()
        elif SettingManager.is_match_key(last_key, 'Ctrl+Z'):
            editor.undo()
            editors[editor]["text"] = editor.text
            _scf(last_key)
            get_viewport().set_input_as_handled()
        elif SettingManager.is_match_shortcut(last_key, 'shortcut', 'new_file'): 
            get_viewport().set_input_as_handled()
        elif SettingManager.is_match_shortcut(last_key, 'shortcut', 'open_file'): 
            get_viewport().set_input_as_handled()
        elif SettingManager.is_match_shortcut(last_key, 'shortcut', 'save_file'): 
            get_viewport().set_input_as_handled()
        elif SettingManager.is_match_shortcut(last_key, 'shortcut', 'open_setting'): 
            get_viewport().set_input_as_handled()

# -------------------------------------------
var last_line = ''
var caret_col = 0
var caret_line = 0
var is_single_letter = true
func _on_text_changed():
    if skip_effect: return
    # this is before shake to get the current typed word by ime
    var old_caret_line = caret_line
    var old_caret_col = caret_col
    caret_line = editor.get_caret_line()
    caret_col =  editor.get_caret_column()
    last_line = editor.get_line(caret_line)
    if last_key == '' or last_key.to_lower() == 'unknown': 
        if caret_line == old_caret_line:
            is_single_letter = false
            last_key = last_line.substr(old_caret_col, caret_col - old_caret_col)
            # Split the multiple keys
            _smc(last_key)
            _imc(last_key)
            emit_signal('typing')
            update_editor_stats()
            last_key = ''
        skip_effect = true
            

func _process(delta):
    
    if shake > 0:
        shake -= delta
        editor.position = Vector2(randf_range(-shake_intensity,shake_intensity), randf_range(-shake_intensity,shake_intensity))
    else:
        editor.position = Vector2.ZERO
    
    timer += delta
    if (pitch_increase > 0.0):
        pitch_increase -= delta * PITCH_DECREMENT

func _ss(duration, intensity):
    if shake > 0:
        return
        
    shake = duration
    shake_intensity = intensity
func _ssf(duration, intensity):
    shake = duration
    shake_intensity = intensity

func caret_changed(textedit):
    editors["line"] = textedit.get_caret_line()
    caret_line = textedit.get_caret_line()
    caret_col = textedit.get_caret_column()

func text_changed(textedit : TextEdit):
    textedit.center_viewport_to_caret()
    _tc.call_deferred(textedit)

func _tc(t:TextEdit):
    if skip_effect:return 
    var l=t.get_line_height()
    var p=t.get_caret_draw_pos()+Vector2(0,-l/2.0)
    emit_signal("typing")
    var u=0
    if editors.has(t):
        var d=len(t.text)-len(editors[t]["text"])
        if timer>.1 and d<0:
            u=1;timer=0;_dc(abs(d)*3)
            if effects.delete:
                var b=Boom.instantiate()
                b.position=p;b.destroy=1;b.last_key=last_key
                b.audio=effects.audio;b.blips=effects.particles
                t.add_child(b)
                if effects.shake:_ss(.2,12)
        if timer>.02 and d>0:
            u=1;timer=0
            if last_key!='Ctrl+V'and last_key!='Ctrl+Y':
                _ic(d*(3 if!is_single_letter else 1))
            if effects.chars:
                var b=Blip.instantiate()
                b.pitch_increase=pitch_increase
                pitch_increase=min(pitch_increase+1,999)
                b.position=p;b.destroy=1;b.last_key=last_key
                b.audio=effects.audio;b.blips=effects.particles
                t.add_child(b)
            if effects.shake:_ss(.05,6)
        if t.get_caret_line()!=editors[t]["line"]:
            u=1
            if effects.newline:
                var n=Newline.instantiate()
                n.position=p;n.destroy=1;n.caret_col=caret_col
                n.last_key=last_key;t.add_child(n);_fc(p)
            if effects.shake:_ss(.08,12)
    if u:editors[t]["text"]=t.text
    editors[t]["line"]=t.get_caret_line()
    update_gutter()
# ---------------------
func _imc(s, mul=3):
    var n = s.length()
    var t = 0.18 + (0.34 if n > 7 else n * 0.04)
    var i = 0
    for k in s:
        _ic(1 if _is_ascii(k) else mul, t * i / n)
        i += 1

func _smc(s: String, f: bool = false) -> void:
    var l = s.length()
    var t = 0.18 + (0.34 if l > 7 else l * 0.04)
    var h = editor.get_line_height() * 0.25
    var x = 0.0
    var o = []
    for c in s: x += h * (2 if c.unicode_at(0) > 127 else 1); o.append(x)
    var p = editor.get_caret_draw_pos() + Vector2(0, -editor.get_line_height()/2.0) + Vector2(x, 0) if f else Vector2.ZERO
    for i in l: _scf(s[i], t * i / l, -x + o[i], p)


func _scf(t, d=0.0, x=0, p=Vector2.ZERO):
    if p == Vector2.ZERO:
        var line_height = editor.get_line_height()
        p = editor.get_caret_draw_pos() + Vector2(0,-line_height/2.0)
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
            # thing.audio = false
            thing.audio = effects.audio
            thing.blips = false
        else:
            thing.audio = effects.audio
            thing.blips = effects.particles
        thing.last_key = t
        editor.add_child(thing)
    
    if effects.shake: _ss(0.05, 6)

# ---------------------

# ---------------------
var skip_effect = false
func feed_ime_input(key):
    skip_effect = true
    last_key = ''

    editor.insert_text_at_caret(key)
    await get_tree().process_frame
    # _smc(key, true)
    _smc(key)
    _imc(key)
    emit_signal('typing')
    update_editor_stats()

func update_editor_stats():
    # update editor
    editors[editor]["text"] = editor.text
    editors[editor]["line"] = editor.get_caret_line()
    update_gutter()
# ---------------------
func _ccnin():
    if combo_node == null or !is_instance_valid(combo_node):
        var thing = Combo.instantiate()
        # thing.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        # thing.set_offsets_preset(Control.PRESET_TOP_RIGHT, 3)
        # thing.grow_horizontal = Control.GROW_DIRECTION_BEGIN
        editor.add_child(thing)
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
    pitch_increase = 0
    if effects.combo:
        if combo_node:
            var count = combo_node.combo_count
            if effects.combo_shot and EffectLaser.can_finish_combo(count) and last_key == 'Enter':
                var thing = Laser.instantiate()
                thing.count = count
                thing.audio = effects.audio
                var font_size = SettingManager.get_basic_setting("font_size")
                match font_size:
                    0: thing.position.y = pos.y + 8
                    1: thing.position.y = pos.y + 12
                    2: thing.position.y = pos.y + 20
                    3: thing.position.y = pos.y + 30
                editor.add_child(thing)

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

#---------------------------
func _init_gutter():
    editor.add_gutter()
    editor.set_gutter_type(0, TextEdit.GUTTER_TYPE_STRING)
    update_gutter()

var _line_number_setted = 1
const SIZE_GUTTER_W = {
    0: 20,
    1: 20,
    2: 25,
    3: 50,
}
func update_gutter():
    var line_count = editor.get_line_count()
    var len = str(line_count).length()
    var font_size = SettingManager.get_basic_setting("font_size")
    var gutter_size = SIZE_GUTTER_W[font_size]
    editor.set_gutter_width(0, max(4*gutter_size, (len+1)*gutter_size))
    if SettingManager.get_basic_setting('line_number'):
        for line in editor.get_line_count():
            var t = '%4d' % [line+1]
            if editor.get_line_gutter_text(line, 0 ) != t:
                editor.set_line_gutter_text(line, 0, t)
                editor.set_line_gutter_item_color(line, 0, '666666')
        _line_number_setted = 1
    else:
        if _line_number_setted:
            for line in editor.get_line_count():
                editor.set_line_gutter_text(line, 0, '')
            _line_number_setted = 0

func _is_ascii(c):
    return c.unicode_at(0) <= 127

func set_caret_line(l):
    editor.set_caret_line(l)
    caret_line = l
func set_caret_column(l):
    editor.set_caret_column(l)
    caret_col = l
