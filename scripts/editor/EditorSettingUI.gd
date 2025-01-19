class_name EditorSettingUI
extends Control

func init():
    visibility_changed.connect(_on_visibility_changed)
    $Close.pressed.connect(_hide)

func _hide():
    hide()
    Editor.view.post_sub_window_hide()

func _on_visibility_changed():
    if visible:
        set_process_input(true)
    else:
        set_process_input(false)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            _hide()
