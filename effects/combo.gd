extends Control

@onready var label: Label = $Label
@onready var label2: Label = $Label2

var shake: float = 0.0
var count: float = 0

# 定义颜色阶段
const COMBO_COLORS = {
    0: Color(0.5, 1, 0.5), 
    8: Color(0.3, 1, 0.3), 
    15: Color(0, 1, 0), 
    30: Color(1, 1, 0), 
    45: Color(1, 0.7, 0),
    60: Color(1, 0.5, 0),
    80: Color(1, 0.2, 0),
    100: Color(1, 0, 0), 
    150: Color(1, 0, 0.5),
    200: Color(1, 0, 1),
}

# 当前颜色
var current_color: Color = Color.WHITE

func _update_text():
    label.text = 'Combo x%d' % max(min(count, 999), 0)
    label2.text = 'Combo x%d' % max(min(count, 999), 0)
    _update_color()

func _update_color():
    # 找到当前combo对应的颜色阶段
    var target_color = COMBO_COLORS[0]  # 默认颜色
    for threshold in COMBO_COLORS:
        if count >= threshold:
            target_color = COMBO_COLORS[threshold]
    
    # 平滑过渡到目标颜色
    current_color = target_color
    label.modulate = current_color

func incr(n=1):
    count += n
    _update_text()
    color_label(5)

func decr(n=1):
    count -= n
    _update_text()
    color_label(3)

func set_count(n):
    count = n
    _update_text()
    color_label(5)

func color_label(duration):
    shake = duration
    TwnLite.at(label, true, '_twn_scale').tween({
        prop='scale',
        from = Vector2(1.6,1.6) * randf_range(1.05, 1.1) * get_count_facor(), 
        to = Vector2(2, 2),
        dur = 0.25 * get_count_facor_time(),
        trans=Tween.TRANS_QUAD,
    })
    TwnLite.at(label).tween({
        prop='self_modulate:a',
        from = 1.0,
        to = 0.0,
        dur = 2.0 * get_count_facor_time(),
        trans=Tween.TRANS_QUAD,
        ease= Tween.EASE_OUT,
    }).callee(
        _reset_count
    )
    TwnLite.at(label2).tween({
        prop='modulate:a',
        from = 2.0,
        to = 0.0,
        dur = 0.3,
        parallel= true,
        trans=Tween.TRANS_SINE,
    }).tween({
        prop='scale',
        from = Vector2(1.6,1.6) * 1.1 *  get_count_facor(),
        to = Vector2(2, 2),
        dur = 0.2 * get_count_facor_time(),
        parallel=  true,
        trans=Tween.TRANS_EXPO,
    })

func _reset_count():
    count = 0
    _update_text()

func get_count_facor():
    return max(1, min(count, 400) / 100.0)
func get_count_facor_time():
    return max(1, (min(count, 400) / 100.0) * 0.5)
