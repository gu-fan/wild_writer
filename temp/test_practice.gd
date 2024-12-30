extends Control

const Boom: PackedScene = preload("res://effects/boom.tscn")
const Blip: PackedScene = preload("res://effects/blip.tscn")

@onready var back_pos: Label = $BackPos  # 背景文字位置参照
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

# 特效相关
var shake: float = 0.0
var shake_intensity: float = 0.0
var pitch_increase: float = 0.0
const TIME_BOOM_INTERVAL = 0.1
var _time_b: float = 0.0
var _time_s: float = 0.0

var effects = {
    audio = 1,
    shake = 1,
    particles = 1,
}

func _ready() -> void:
    target_text = back.text
    type.text = ""
    type.modulate.a = 0.6
    _update_stats()

func _physics_process(delta: float) -> void:
    _time_b += delta
    
    if shake > 0:
        shake -= delta
        position = Vector2(randf_range(-shake_intensity, shake_intensity), 
                         randf_range(-shake_intensity, shake_intensity))
    else:
        position = Vector2.ZERO

    _time_s += delta
    if is_started and _time_s > 0.1:
        _update_stats()
        _time_s = 0

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
            
            # 删除特效
            if _time_b > TIME_BOOM_INTERVAL:
                var thing = Boom.instantiate()
                thing.position = _get_cursor_position()
                thing.destroy = true
                thing.audio = effects.audio
                thing.blips = effects.particles
                add_child(thing)
                _time_b = 0.0
                if effects.shake:
                    _shake(0.2, 12)
        return

    if event.unicode == 0:
        return
        
    # 普通字符输入
    var typed_char = char(event.unicode)
    if current_pos < target_text.length():
        if typed_char == target_text[current_pos]:
            current_pos += 1
            _update_display_text()
            _show_type_effect(typed_char)
            _check_completion()
        else:
            errors += 1
            if not current_pos in error_positions:
                error_positions.append(current_pos)
            current_pos += 1
            _update_display_text()
            _show_type_effect(typed_char, true)
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
    
    error.text = "Err: %d" % errors

func _show_type_effect(key: String, is_error: bool = false) -> void:
    var thing = Blip.instantiate()
    thing.position = _get_cursor_position()
    thing.pitch_increase = pitch_increase
    pitch_increase += 1.0
    pitch_increase = min(pitch_increase, 999)
    thing.destroy = true
    thing.audio = effects.audio
    thing.blips = effects.particles
    thing.last_key = key
    if is_error:
        thing.modulate = Color.RED
    add_child(thing)
    
    if effects.shake:
        _shake(0.05, 6)

func _shake(duration: float, intensity: float) -> void:
    if shake > 0:
        return
    shake = duration
    shake_intensity = intensity

func _get_cursor_position() -> Vector2:
    # 使用 back_pos 获取字符位置
    var bounds = back_pos.get_character_bounds(current_pos)
    if bounds:
        # 返回字符中心位置
        return bounds.position + Vector2(bounds.size.x/2, bounds.size.y/2)
    
    # 如果获取失败，使用备用方法
    var base_pos = type.position
    var font_size = type.get_theme_font_size("normal_font_size")
    var x_offset = current_pos * (font_size * 0.6)
    return base_pos + Vector2(x_offset, font_size/2)
