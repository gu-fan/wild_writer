extends Node2D


var file_manager: FileManager

@onready var ime = TinyIME
@onready var settings: Control = $CanvasLayer/Settings

@onready var bottom_label: Label = $CanvasLayer/VBoxContainer/BottomPanel/HBoxContainer/Label
@onready var ime_button: Button = $CanvasLayer/VBoxContainer/BottomPanel/HBoxContainer/IMEButton
@onready var setting_button: Button = $CanvasLayer/VBoxContainer/BottomPanel/HBoxContainer/SettingButton
@onready var editor_man: TinyEditor = $CanvasLayer
var editor

var current_file_path = ''

func _ready():
    file_manager = FileManager.new()
    add_child(file_manager)

    editor = editor_man.editor

    set_title('Untitled')

    editor_man.bottom_label = bottom_label
    editor_man.ime_button = ime_button
    editor_man.setting_button = setting_button
    editor_man.init()

    setting_button.pressed.connect(_toggle_setting)

    SettingManager.setting_changed.connect(load_settings)
    load_settings()

func load_settings():
    var auto_open_recent =  SettingManager.get_setting('basic', 'auto_open_recent')
    if auto_open_recent:
        var recent_file = SettingManager.get_setting('basic', 'recent_file')
        if recent_file:
            current_file_path = recent_file
            file_manager.open_file(editor, current_file_path)
            set_title(current_file_path)
            show_hint(':opened %s' % current_file_path)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("save"):
        if current_file_path == '':
            current_file_path = await file_manager.show_save_dialog()
            set_title(current_file_path)
        file_manager.save_file(editor, current_file_path)
        show_hint(':saved %s' % current_file_path)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("open"):
        var file_path = await file_manager.show_open_dialog()
        file_manager.open_file(editor, file_path)
        current_file_path = file_path
        set_title(current_file_path)
        show_hint(':opened %s' % current_file_path)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("new"):
        file_manager.new_file(editor)
        current_file_path = ''
        set_title('Untitled')
        show_hint(':created new untitled file')
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("setting"):
        # settings.show()
        _toggle_setting()
        get_viewport().set_input_as_handled()

func set_title(file_path):
    DisplayServer.window_set_title(file_path)

func show_hint(txt):
    bottom_label.text = txt
    await get_tree().create_timer(4.0).timeout
    bottom_label.text = ''

func _toggle_setting():
    settings.visible = !settings.visible
    if settings.visible:
        ime.disabled = true
        editor_man.editor.editable = false
        editor_man.editor.release_focus()
    else:
        ime.disabled = false
        editor_man.editor.editable = true
        editor_man.editor.grab_focus()
