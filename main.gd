extends Node2D

signal typing

const Boom: PackedScene = preload("res://boom.tscn")
const Blip: PackedScene = preload("res://blip.tscn")
const Newline: PackedScene = preload("res://newline.tscn")
const Dock: PackedScene = preload("res://dock.tscn")

const PITCH_DECREMENT := 2.0

var shake: float = 0.0
var shake_intensity:float  = 0.0
var timer: float = 0.0
var last_key: String = ""
var pitch_increase: float = 0.0
var editors = {}

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var editor: TextEdit = $CanvasLayer/VBoxContainer/TextEdit
@onready var bottom_panel: ColorRect = $CanvasLayer/VBoxContainer/BottomPanel
@onready var dock: Control = $CanvasLayer/VBoxContainer/Dock
@onready var bottom_label: Label = $CanvasLayer/VBoxContainer/BottomPanel/Label

var file_manager: FileManager
var current_file_path = ''

func _ready():
    typing.connect(Callable(dock,"_on_typing"))
    setup_editor([editor])
    file_manager = FileManager.new()
    add_child(file_manager)
    set_title('Untitled')

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
        print(last_key, event)

        if last_key == 'Ctrl+S':
            get_viewport().set_input_as_handled()
        elif last_key == 'Ctrl+O':
            get_viewport().set_input_as_handled()
        elif last_key == 'Ctrl+N':
            get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        dock.visible = !dock.visible
    elif event.is_action_pressed("save"):
        if current_file_path == '':
            current_file_path = await file_manager.show_save_dialog()
            set_title(current_file_path)
        file_manager.save_file(editor, current_file_path)
        show_hint('saved')
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("open"):
        var file_path = await file_manager.show_open_dialog()
        file_manager.open_file(editor, file_path)
        current_file_path = file_path
        set_title(current_file_path)
        show_hint('opened')
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("new"):
        file_manager.new_file(editor)
        current_file_path = ''
        set_title('Untitled')
        show_hint('create new')
        get_viewport().set_input_as_handled()

func set_title(file_path):
    DisplayServer.window_set_title(file_path)

func show_hint(txt):
    bottom_label.text = txt
    await get_tree().create_timer(2.0).timeout
    bottom_label.text = ''

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
