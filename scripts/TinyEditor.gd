class_name TinyEditor
extends CanvasLayer

signal typing

@onready var ime = TinyIME
@onready var editor: TextEdit = $Control/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/TextEdit
@onready var pad: Control = $Control/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/Padding

const Boom: PackedScene    = preload("res://effects/boom.tscn")
const Combo: PackedScene   = preload("res://effects/combo.tscn")
const Laser: PackedScene   = preload("res://effects/laser.tscn")
const Blip: PackedScene    = preload("res://effects/blip.tscn")
const Newline: PackedScene = preload("res://effects/newline.tscn")

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
var b_timer: float = 0.0
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

var last_line = ''
var caret_col = 0
var caret_line = 0
var is_single_letter = true


var is_split_view: bool = false
@onready var editor_secondary: TextEdit = $Control/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer2/TextEdit
@onready var pad_secondary: Control = $Control/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer2/Padding
@onready var splitter: HSplitContainer = $Control/MarginContainer/VBoxContainer/VSplitContainer

func _ready():
    var b = Boom.instantiate()
    b.audio = false
    b.blips = false
    b.hide()
    add_child(b)
    var l = Laser.instantiate()
    l.audio = false
    l.hide()
    add_child(l)

func init():

    editor_main = get_tree().current_scene

    ime_display = preload("res://scenes/ime_display.tscn").instantiate()
    ime_display.hide()
    add_child(ime_display)

    ime_display.feed_ime_input.connect(feed_ime_input)
    ime_button.pressed.connect(ime.toggle)
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
    setup_split_container()


func setup_split_container():
    # Create secondary editor when needed
    # if not editor_secondary:
        # editor_secondary = editor.duplicate()
        # editor_secondary.text = editor.text
        # editor_secondary.hide()
        # splitter.add_child(editor_secondary)
    setup_editor([editor_secondary])  # Setup effects and handlers

func toggle_split_view():
    is_split_view = !is_split_view
    if is_split_view:
        # Show split view
        editor_secondary.show()
        editor_secondary.text = editor.text
        # Sync scroll positions
        editor_secondary.scroll_vertical = editor.scroll_vertical
        editor_secondary.scroll_horizontal = editor.scroll_horizontal
    else:
        # Hide split view
        editor_secondary.hide()

func update_ime_position():
    if ime_display and ime_display.visible:
        await get_tree().process_frame
        var line_height = editor.get_line_height()
        var ime_height = ime_display.size.y
        var caret_pos = _gfcp()
        
        var pos = editor.position + caret_pos + Vector2(0, line_height)
        match font_size:
            0: pos.y += 40
            1: pos.y += 30
            2: pos.y += 16
            3: pos.y -= 75

        if pos.y > editor.size.y-10: 
            pos = editor.position + caret_pos + Vector2(0, -line_height)
            match font_size:
                0: pos.y += 12
                1: pos.y += 6
                2: pos.y += 2
                3: pos.y -= 4
        
            
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
            child.text_changed.connect(_otc)
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
        if SettingManager.is_match_shortcut(last_key, 'ime', 'switch_ime_key'):
            ime.toggle()
            get_viewport().set_input_as_handled()
        elif last_key.to_lower() in ['up', 'down', 'right', 'left']:
            _show_char_force(last_key)
            pitch_increase -= 1.0
        elif last_key.to_lower() in ['ctrl+c', 'cmd+c']:
            var selected = editor.get_selected_text()
            DisplayServer.clipboard_set(selected)
            if OS.get_name() == 'Linux':
                DisplayServer.clipboard_set_primary(selected)
            _show_char_force(last_key)
            get_viewport().set_input_as_handled()
        elif last_key.to_lower() in ['ctrl+x', 'cmd+x']:
            var selected = editor.get_selected_text()
            DisplayServer.clipboard_set(selected)
            if OS.get_name() == 'Linux':
                DisplayServer.clipboard_set_primary(selected)
            _show_char_force(last_key)
            editor.backspace()
            get_viewport().set_input_as_handled()
        elif last_key.to_lower() in ['ctrl+v', 'cmd+v']:
            editor.insert_text_at_caret(DisplayServer.clipboard_get())
            _show_char_force(last_key)
            skip_effect = true
            get_viewport().set_input_as_handled()
        elif last_key.to_lower() in ['ctrl+a', 'cmd+a']:
            editor.select_all()
            _show_char_force(last_key)
            get_viewport().set_input_as_handled()
        elif last_key.to_lower() in ['ctrl+z', 'cmd+z']:
            editor.undo()
            editors[editor]["text"] = editor.text
            _show_char_force(last_key)
            get_viewport().set_input_as_handled()
        elif SettingManager.is_match_shortcut(last_key, 'shortcut', 'split_view'): 
            toggle_split_view()
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
func _otc():
    if skip_effect:return
    var o=caret_line
    var p=caret_col
    caret_line=editor.get_caret_line()
    caret_col=editor.get_caret_column()
    last_line=editor.get_line(caret_line)
    if last_key==''or last_key.to_lower()=='unknown':
        if caret_line==o:
            is_single_letter=false
            last_key=last_line.substr(p,caret_col-p)
            _show_multi_char(last_key)
            _incr_multi_combo(last_key)
            emit_signal('typing')
            update_editor_stats()
            last_key=''
        skip_effect=true

func _process(delta):
    
    if shake > 0:
        shake -= delta
        editor.position = Vector2(randf_range(-shake_intensity,shake_intensity), randf_range(-shake_intensity,shake_intensity))
    else:
        editor.position = Vector2.ZERO
    
    # var ime_text = DisplayServer.ime_get_text()
    # print('ime', ime_text)
    timer += delta
    b_timer += delta
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
    
    center_viewport_to_caret(textedit)
    # _tc.call_deferred(textedit)
    await get_tree().process_frame
    _tc(textedit)

func _tc(textedit:TextEdit):
    if skip_effect: return 
    var line_height = textedit.get_line_height()
    var pos = _gfcp() + Vector2(0,-line_height/2.0)
    emit_signal("typing")
    
    var is_text_updated = false
    if editors.has(textedit):

        var len_d = len(textedit.text) - len(editors[textedit]["text"])

        # Deleting
        if b_timer > 0.1 and len_d < 0:
            is_text_updated = true
            b_timer = 0.0
            _dc(abs(len_d)*3)
            
            if effects.delete:
                # Draw the thing
                var thing = Boom.instantiate()
                thing.position = pos
                thing.destroy = true
                thing.last_key = last_key
                thing.audio = effects.audio
                thing.blips = effects.particles
                textedit.add_child(thing)
                    
                if effects.shake:
                    _ss(0.2, 12)
        
        # Typing
        if timer > 0.02 and len_d > 0:
            is_text_updated = true
            timer = 0.0
            if last_key != 'Ctrl+V' and last_key != 'Ctrl+Y':
                if is_single_letter:
                    _ic(len_d)
                else:
                    _ic(len_d*3) # average is 4

            
            # Draw the thing
            if effects.chars: 
                var thing = Blip.instantiate()
                thing.pitch_increase = pitch_increase
                pitch_increase += 1.0
                pitch_increase = min(pitch_increase, 999)
                thing.position = pos
                thing.destroy = true
                thing.audio = effects.audio
                thing.blips = effects.particles
                thing.last_key = last_key
                textedit.add_child(thing)
            
            if effects.shake:
                match font_size:
                    # _ss(0.05, 6)
                    0: _ss(0.04, 3)
                    1: _ss(0.04, 4)
                    2: _ss(0.05, 5)
                    3: _ss(0.05, 6)
            
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

                _fc(pos)
            if effects.shake:
                _ss(0.08, 8)
    
    if is_text_updated: editors[textedit]["text"] = textedit.text
    editors[textedit]["line"] = textedit.get_caret_line()
    update_gutter()
# ---------------------
func _incr_multi_combo(s, mul=3):
    var n = s.length()
    var t = 0.18 + (0.34 if n > 7 else n * 0.04)
    var i = 0
    for k in s:
        _ic(1 if _is_ascii(k) else mul, t * i / n)
        i += 1

func _show_multi_char(s: String, f: bool = false) -> void:
    var l = s.length()
    var t = 0.18 + (0.34 if l > 7 else l * 0.04)
    var h = editor.get_line_height() * 0.25
    var x = 0.0
    var o = []
    for c in s: x += h * (2 if c.unicode_at(0) > 127 else 1); o.append(x)
    var p = editor.get_caret_draw_pos() + Vector2(0, -editor.get_line_height()/2.0) + Vector2(x, 0) if f else Vector2.ZERO
    for i in l: _show_char_force(s[i], t * i / l, -x + o[i], p)

func _show_char_force(t, d=0.0, x=0, p=Vector2.ZERO):
    await get_tree().process_frame
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
            thing.audio = effects.audio
            thing.blips = false
        else:
            thing.audio = effects.audio
            thing.blips = effects.particles
        thing.last_key = t
        editor.add_child(thing)
    
    if effects.shake: 
        match font_size:
            0: _ss(0.04, 3)
            1: _ss(0.04, 4)
            2: _ss(0.05, 5)
            3: _ss(0.05, 6)
        

# ---------------------
var skip_effect = false
func feed_ime_input(key):
    skip_effect = true
    last_key = ''

    editor.insert_text_at_caret(key)
    await get_tree().process_frame
    _show_multi_char(key)
    _incr_multi_combo(key)
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
                thing.position.y = pos.y + 3
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
func _gfcp():
    var cp = editor.get_caret_draw_pos()
    var lh = editor.get_line_height()
    if caret_col == 0 and caret_line != 0: cp.y += lh * 0.45
    return cp
# func _gfcp() -> Vector2:
#     # Get the rect for current caret position
#     caret_line = editor.get_caret_line()
#     caret_col = editor.get_caret_column()
#     var rect = editor.get_rect_at_line_column(caret_line, caret_col)
#     var pos = rect.position
#     var pos2 = editor.get_pos_at_line_column(caret_line, caret_col)
    
#     # Add vertical offset for empty lines
#     var line_height = editor.get_line_height()
#     if caret_col == 0:
#         if caret_line != 0:
#             pos.y += line_height * 0.45
#         else:
#             print('draw')
#             pos = editor.get_caret_draw_pos()
        
#     prints('pos> ', pos, pos2, caret_line, caret_col)
#     # Ensure position is within visible area
#     # var visible_rect = editor.get_visible_rect()
#     # pos.x = clamp(pos.x, visible_rect.position.x, visible_rect.position.x + visible_rect.size.x)
#     # pos.y = clamp(pos.y, visible_rect.position.y, visible_rect.position.y + visible_rect.size.y)
#     # print('pos< ', pos)
    
#     return pos2

func _notification(what):
    if what == NOTIFICATION_OS_IME_UPDATE:
        # print('note ime:', DisplayServer.ime_get_text())
        pass

func center_viewport_to_caret(textedit:TextEdit):
    # Get current caret line with wrap
    var caret_line = textedit.get_caret_line() + textedit.get_caret_wrap_index()
    
    # Calculate lines below caret
    var visible_lines = textedit.get_visible_line_count()
    var first_visible = textedit.get_first_visible_line()
    var lines_below_caret = visible_lines - (caret_line - first_visible) - 1
    
    # Calculate remaining lines in file
    var total_lines = textedit.get_line_count()
    var lines_remaining = total_lines - (caret_line + 1)
    var required_empty_lines = 3

    var _pad = pad if textedit == editor else pad_secondary
    
    # Adjust padding if near file end
    if lines_remaining < required_empty_lines:
        var line_height = textedit.get_line_height()
        var extra_padding = (required_empty_lines - lines_remaining - 1) * line_height
        _pad.custom_minimum_size = Vector2(10, extra_padding)
    else:
        _pad.custom_minimum_size = Vector2(10, 0)
    
    # Only scroll if less than 3 lines below caret
    if lines_below_caret < required_empty_lines:
        # Calculate target line to be 2 lines from bottom
        var target_line = caret_line - (visible_lines - required_empty_lines)
        target_line = maxi(0, target_line)
        textedit.set_line_as_first_visible(target_line)

func _hki(event: InputEventKey) -> void:
    if event.pressed:
        var key_string = OS.get_keycode_string(event.get_keycode_with_modifiers())
        # Get raw keycode for IME comparison
        var raw_keycode = event.get_keycode()
        # Check if this is an IME composition key
        if raw_keycode == KEY_SHIFT or raw_keycode == KEY_CTRL or raw_keycode == KEY_ALT:
            return
        # Rest of your existing code...
