class_name GoalWindow extends Window

signal window_canceled

@onready var g_1: Button = $Box/G1
@onready var g_2: Button = $Box/G2
@onready var g_3: Button = $Box/G3
@onready var g_ok: Button = $OK

func _input(event: InputEvent) -> void:
    if not has_focus(): return

    if event is InputEventKey and event.pressed:
        prints(event.keycode, KEY_ENTER, KEY_KP_ENTER)
        if event.keycode == KEY_ESCAPE:
            emit_signal("window_canceled")
        if event.keycode == KEY_1:
            g_1.set_pressed(true)
        elif event.keycode == KEY_2:
            g_2.button_pressed = true
        elif event.keycode == KEY_3:
            g_3.button_pressed = true
        elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            # g_ok.button_pressed = true
            g_ok.pressed.emit()
