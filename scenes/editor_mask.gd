extends ColorRect


var _current_window
var _current_window_cancel_func
var _trigger_with_click = false

func _ready():
    set_process_input(false)
    visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
    if visible:
        set_process_input(true)
    else:
        set_process_input(false)

func _unhandled_input(event: InputEvent) -> void:
    if !visible: return

    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            if _current_window:
                _current_window_cancel_func.call()
                clear_window()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if _current_window and _trigger_with_click:
            print('clear window called with click')
            _current_window_cancel_func.call()
            clear_window()

func set_window(win, cancel_func, _with_click=false):
    _current_window = win
    _current_window_cancel_func = cancel_func
    _trigger_with_click = _with_click

func clear_window():
    _current_window = null
    _current_window_cancel_func = null
    _trigger_with_click = false
