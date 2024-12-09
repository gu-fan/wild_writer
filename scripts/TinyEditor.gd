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

func init():
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

    editor_main = get_tree().current_scene

func update_ime_position():
    if ime_display and ime_display.visible:
        var caret_pos = editor.get_caret_draw_pos()
        var line_height = editor.get_line_height()
        var ime_height = ime_display.size.y
        
        # 计算默认位置（光标上方）
        var pos = editor.position + caret_pos + Vector2(0, -line_height - 20)
        
        # 如果位置会导致 IME 超出顶部，则将其放在光标下方
        if pos.y < 10: pos.y = editor.position.y + caret_pos.y + line_height
            
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
        if last_key == 'Shift+Escape':
            ime.toggle_ime()
            get_viewport().set_input_as_handled()
        elif last_key == 'Ctrl+S':
            get_viewport().set_input_as_handled()
        elif last_key == 'Ctrl+O':
            get_viewport().set_input_as_handled()
        elif last_key == 'Ctrl+N':
            get_viewport().set_input_as_handled()

# -------------------------------------------
var last_line = ''
var caret_col = 0
var caret_line = 0
var is_single_letter = true
func _on_text_changed():
    # this is before shake to get the current typed word by ime
    var old_caret_line = caret_line
    var old_caret_col = caret_col
    caret_line = editor.get_caret_line()
    caret_col =  editor.get_caret_column()
    last_line = editor.get_line(caret_line)
    if last_key == '': 
        if caret_line == old_caret_line:
            is_single_letter = false
            last_key = last_line.substr(old_caret_col, caret_col - old_caret_col)

func _process(delta):
    
    if shake > 0:
        shake -= delta
        editor.position = Vector2(randf_range(-shake_intensity,shake_intensity), randf_range(-shake_intensity,shake_intensity))
    else:
        editor.position = Vector2.ZERO
    
    timer += delta
    if (pitch_increase > 0.0):
        pitch_increase -= delta * PITCH_DECREMENT

func shake_screen(duration, intensity):
    if shake > 0:
        return
        
    shake = duration
    shake_intensity = intensity
func shake_screen_force(duration, intensity):
    shake = duration
    shake_intensity = intensity

func caret_changed(textedit):
    editors["line"] = textedit.get_caret_line()

func text_changed(textedit : TextEdit):
    textedit.center_viewport_to_caret()
    _text_changed.call_deferred(textedit)

func _text_changed(textedit: TextEdit):

    var line_height = textedit.get_line_height()
    var pos = textedit.get_caret_draw_pos() + Vector2(0,-line_height/2.0)
    emit_signal("typing")
    
    var is_text_updated = false
    if editors.has(textedit):

        var len_d = len(textedit.text) - len(editors[textedit]["text"])

        # Deleting
        if timer > 0.1 and len_d < 0:
            is_text_updated = true
            timer = 0.0
            decr_combo(abs(len_d))
            
            if effects.delete:
                # Draw the thing
                if effects.chars: 
                    var thing = Boom.instantiate()
                    thing.position = pos
                    thing.destroy = true
                    thing.last_key = last_key
                    thing.audio = effects.audio
                    textedit.add_child(thing)
                    
                if effects.shake:
                    shake_screen(0.3, 9)
        
        # Typing
        if timer > 0.02 and len_d > 0:
            is_text_updated = true
            timer = 0.0
            if is_single_letter:
                incr_combo(len_d)
            else:
                incr_combo(len_d*3) # average is 4
            
            # Draw the thing
            if effects.chars: 
                var thing = Blip.instantiate()
                thing.pitch_increase = pitch_increase
                pitch_increase += 1.0
                pitch_increase = min(pitch_increase, 999)
                thing.position = pos
                thing.destroy = true
                thing.audio = effects.audio
                thing.last_key = last_key
                textedit.add_child(thing)
            
            if effects.shake:
                shake_screen(0.05, 6)
            
        # Newline
        if textedit.get_caret_line() != editors[textedit]["line"]:
            is_text_updated = true
            # Draw the thing
            if effects.newline:
                var thing = Newline.instantiate()
                thing.position = pos 
                thing.destroy = true
                thing.caret_col = caret_col
                thing.last_key = last_key
                textedit.add_child(thing)

                finish_combo(pos)
            if effects.shake:
                shake_screen(0.05, 12)
    
    if is_text_updated: editors[textedit]["text"] = textedit.text
    editors[textedit]["line"] = textedit.get_caret_line()
    _update_gutter()

# ---------------------
func _update_edit_cache():
    editors[editor]["text"] = editor.text
    editors[editor]["line"] = editor.get_caret_line()

# ---------------------
func feed_ime_input(key):
    last_key = key
    is_single_letter = false
    editor.insert_text_at_caret(key)
# ---------------------
func create_combo_node_if_null():
    if combo_node == null or !is_instance_valid(combo_node):
        var thing = Combo.instantiate()
        # thing.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        # thing.set_offsets_preset(Control.PRESET_TOP_RIGHT, 3)
        # thing.grow_horizontal = Control.GROW_DIRECTION_BEGIN
        editor.add_child(thing)
        combo_node = thing

func incr_combo(n=1):
    if effects.combo:
        create_combo_node_if_null()
        combo_node.incr(n)

func decr_combo(n=1):
    if effects.combo:
        if combo_node:
            combo_node.decr(n)
            if combo_node.count <= 0:
                remove_combo()

func finish_combo(pos):
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
                    shake_screen_force(EffectLaser.get_main_duration(count)-0.3, size * 3)
            combo_node.queue_free()
            combo_node = null

func remove_combo():
    pitch_increase = 0
    if effects.combo:
        if combo_node:
            combo_node.queue_free()
            combo_node = null

#---------------------------
func _init_gutter():
    editor.add_gutter()
    editor.set_gutter_type(0, TextEdit.GUTTER_TYPE_STRING)
    _update_gutter()

var _line_number_setted = 1
const SIZE_GUTTER_W = {
    0: 20,
    1: 20,
    2: 25,
    3: 50,
}
func _update_gutter():
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
