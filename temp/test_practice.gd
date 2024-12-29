extends Control

@onready var back: RichTextLabel = $Back  # 背景文字
@onready var type: RichTextLabel = $Type  # 用户输入的文字
@onready var time: Label = $VBox/Time
@onready var wpm: Label = $VBox/Wpm
@onready var acc: Label = $VBox/Acc
@onready var error: Label = $VBox/Error

var target_text: String = ""
var current_pos: int = 0
var errors: int = 0
var start_time: float = 0.0
var is_started: bool = false
var error_positions: Array[int] = []

func _ready() -> void:
    target_text = back.text
    type.text = ""
    type.modulate.a = 0.6
    _update_stats()

func _process(_delta: float) -> void:
    if is_started:
        _update_stats()

func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed:
        return
        
    # 开始计时
    if not is_started and event.keycode != KEY_ESCAPE:
        is_started = true
        start_time = Time.get_unix_time_from_system()
    
    # ESC 重置
    if event.keycode == KEY_ESCAPE:
        _reset()
        return
        
    # 忽略修饰键
    if event.is_command_or_control_pressed() or event.is_alt_pressed():
        return
        
    # 退格键处理
    if event.keycode == KEY_BACKSPACE:
        if current_pos > 0:
            current_pos -= 1
            # 如果删除的是错误字符，从错误列表中移除
            if current_pos in error_positions:
                error_positions.erase(current_pos)
            _update_display_text()
        return
        
    # 普通字符输入
    var typed_char = char(event.unicode)
    if current_pos < target_text.length():
        if typed_char == target_text[current_pos]:
            current_pos += 1
            _update_display_text()
            _check_completion()
        else:
            errors += 1
            if not current_pos in error_positions:
                error_positions.append(current_pos)
            current_pos += 1
            _update_display_text()
            _check_completion()

func _update_display_text() -> void:
    var display_text = ""
    for i in range(current_pos):
        var char_to_add = target_text[i]
        if i in error_positions:
            if char_to_add == " ":
                display_text += "[color=red]_[/color]"
            else:
                display_text += "[color=red]" + char_to_add + "[/color]"
        else:
            display_text += "[color=5388ff]" + char_to_add + "[/color]"
    type.text = display_text

func _check_completion() -> void:
    if current_pos >= target_text.length():
        var end_time = Time.get_unix_time_from_system()
        var duration = end_time - start_time
        var wpm = _calculate_wpm(duration)
        var accuracy = _calculate_accuracy()
        
        # 显示结果
        prints("完成！")
        prints("时间：%.1f秒" % duration)
        prints("WPM：%.1f" % wpm)
        prints("准确率：%.1f%%" % accuracy)
        prints("错误数：%d" % errors)

func _calculate_wpm(duration: float) -> float:
    # WPM = (字符数 / 5) / 分钟数
    return (target_text.length() / 5.0) / (duration / 60.0)

func _calculate_accuracy() -> float:
    var total_keystrokes = target_text.length() + errors
    return (target_text.length() / float(total_keystrokes)) * 100.0

func _reset() -> void:
    current_pos = 0
    errors = 0
    error_positions.clear()
    type.text = ""
    is_started = false

func _update_stats() -> void:
    var duration = 0.0
    if is_started:
        duration = Time.get_unix_time_from_system() - start_time
    
    time.text = "Time: %.1f s" % duration
    
    var current_wpm = 0.0
    if duration > 0:
        current_wpm = _calculate_wpm(duration)
    wpm.text = "WPM: %.1f" % current_wpm
    
    var accuracy = _calculate_accuracy()
    acc.text = "Acc: %.1f%%" % accuracy
    
    error.text = "Errors: %d" % errors
