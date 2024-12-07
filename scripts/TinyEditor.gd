class_name TinyEditor
extends CanvasLayer

signal typing

@onready var ime = TinyIME
@onready var editor: TextEdit = $VBoxContainer/TextEdit
@onready var dock: Control = $VBoxContainer/Dock

const Boom: PackedScene = preload("res://effects/boom.tscn")
const Blip: PackedScene = preload("res://effects/blip.tscn")
const Newline: PackedScene = preload("res://effects/newline.tscn")
const Dock: PackedScene = preload("res://scenes/dock.tscn")

const PITCH_DECREMENT := 2.0

var shake: float = 0.0
var shake_intensity:float  = 0.0
var timer: float = 0.0
var last_key: String = ""
var pitch_increase: float = 0.0
var editors = {}

var ime_display
var ime_button
var setting_button
var bottom_label


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
    typing.connect(Callable(dock,"_on_typing"))

func update_ime_position():
    if ime_display and ime_display.visible:
        var caret_pos = editor.get_caret_draw_pos()
        var line_height = editor.get_line_height()
        var ime_height = ime_display.size.y
        
        # 计算默认位置（光标上方）
        var pos = editor.position + caret_pos + Vector2(0, -line_height - 40)
        
        # 如果位置会导致 IME 超出顶部，则将其放在光标下方
        if pos.y < 10:
            pos.y = editor.position.y + caret_pos.y + line_height
            
        # 确保不会超出右边界
        var editor_width = editor.size.x
        if pos.x + ime_display.size.x > editor_width:
            pos.x = editor_width - ime_display.size.x
            
        # 确保不会超出左边界
        if pos.x < 0:
            pos.x = 0
            
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

        if last_key == 'Shift+Space':
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
func _on_text_changed():
    # this is before shake to get the current typed word by ime
    var old_caret_line = caret_line
    var old_caret_col = caret_col
    caret_line = editor.get_caret_line()
    caret_col =  editor.get_caret_column()
    last_line = editor.get_line(caret_line)
    if last_key == '': 
        if caret_line == old_caret_line:
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


func caret_changed(textedit):
    
    editors["line"] = textedit.get_caret_line()

func text_changed(textedit : TextEdit):
    var line_height = textedit.get_line_height()
    var pos = textedit.get_caret_draw_pos() + Vector2(0,-line_height/2.0)
    emit_signal("typing")
    
    if editors.has(textedit):

        # print('last', last_key)

        # if last_key == 'Ctrl+S': return
        # if last_key == 'Ctrl+O': return
        # if last_key == 'Ctrl+N': return
        # Deleting
        if timer > 0.1 and len(textedit.text) < len(editors[textedit]["text"]):
            timer = 0.0
            
            if dock.explosions:
                # Draw the thing
                var thing = Boom.instantiate()
                thing.position = pos
                thing.destroy = true
                if dock.chars: thing.last_key = last_key
                thing.sound = dock.sound
                textedit.add_child(thing)
                # thing.top_level = true
                
                if dock.shake:
                    # Shake
                    shake_screen(0.3, 20)
        
        # Typing
        if timer > 0.02 and len(textedit.text) >= len(editors[textedit]["text"]):
            timer = 0.0
            
            # Draw the thing
            var thing = Blip.instantiate()
            thing.pitch_increase = pitch_increase
            pitch_increase += 1.0
            thing.position = pos
            thing.destroy = true
            thing.blips = dock.blips
            if dock.chars: thing.last_key = last_key
            thing.sound = dock.sound
            # thing.top_level = true
            textedit.add_child(thing)
            
            if dock.shake:
                # Shake
                shake_screen(0.05, 8)
            
        # Newline
        if textedit.get_caret_line() != editors[textedit]["line"]:
            # Draw the thing
            var thing = Newline.instantiate()
            thing.position = pos
            thing.destroy = true
            thing.blips = dock.blips
            textedit.add_child(thing)
            thing.top_level = true
            
            if dock.shake:
                # Shake
                shake_screen(0.05, 8)
    
    editors[textedit]["text"] = textedit.text
    editors[textedit]["line"] = textedit.get_caret_line()

# ---------------------
func feed_ime_input(key):
    last_key = key
    editor.insert_text_at_caret(key)
    # _on_text_changed()
    # text_changed(editor)
