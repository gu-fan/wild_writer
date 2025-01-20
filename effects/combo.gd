extends Control


var shake: float = 0.0
var count: float = 0
var combo_count : float = 0 : 
    get:
        return count - 10
var on_count_reset = null

@onready var label: Label = $Label
@onready var label2: Label = $Label2
@onready var label3: Label = $Label/Label3

# 定义颜色阶段
const COMBO_COLORS = {
    # 0:   Color(0.5, 1, 0.5),
    # 8:   Color(0.3, 1, 0.3),
    # 15:  Color(0, 1, 0),
    # 30:  Color(.8, .8, 0),
    # 45:  Color(.8, 0.7, 0),
    # 60:  Color(1, 0.5, 0),
    # 80:  Color(1, 0.2, 0),
    # 100: Color(1, 0, 0),
    # 150: Color(1, 0, 0.5),
    # 200: Color(1, 0, 1),
    0:   Color('00FF33'),
    40:  Color('99FF00'),
    80:  Color('FF9900'),
    120:  Color('FF3333'),
    160:  Color('FF3399'),
    200: Color('FF00FF'),
}

# 当前颜色
var _current_color: Color = Color.WHITE
var font_size = 1
var font_res = ''
func _ready():
    var extra_scale = 1
    if font_size == 2: 
        extra_scale = 1.5
    elif font_size == 3: 
        extra_scale = 2

    label.scale =  Vector2.ONE * extra_scale
    label2.scale =  Vector2.ONE * extra_scale
    if font_res:
        label.set("theme_override_fonts/font", font_res)
        label2.set("theme_override_fonts/font", font_res)
        label3.set("theme_override_fonts/font", font_res)

func _update_text():
    if count <= 10:
        label.hide()
        label2.hide()
        label3.hide()
    else:
        label.show()
        label2.show()
        label3.show()
        label.text = 'Combo x%d' % max(min(combo_count, 999), 0)
        label2.text = 'Combo x%d' % max(min(combo_count, 999), 0)
        label3.text = 'Combo x%d' % max(min(combo_count, 999), 0)
        _update_color()

func _update_color():

    var target_color = COMBO_COLORS[0]  # 默认颜色
    var previous_threshold = 0
    var next_threshold = 0
    var previous_color = COMBO_COLORS[0]
    var next_color = COMBO_COLORS[0]
    
    for threshold in COMBO_COLORS:
        if combo_count >= threshold:
            previous_threshold = threshold
            previous_color = COMBO_COLORS[threshold]
        else:
            next_threshold = threshold
            next_color = COMBO_COLORS[threshold]
            break
    
    # 计算插值权重
    var weight = 0.0
    if next_threshold > previous_threshold:
        weight = float(combo_count - previous_threshold) / float(next_threshold - previous_threshold)
    
    # 平滑过渡到目标颜色
    target_color = previous_color.lerp(next_color, weight)
    _current_color = target_color
    label.modulate = _current_color
    label3.modulate = Color(_current_color).lightened(0.2)

func incr(n=1):
    count += n
    if label == null: return
    _update_text()
    if count > 10: color_label()

func decr(n=1):
    count -= n
    if label == null: return
    _update_text()
    if count > 10: color_label()

func set_count(n):
    count = n
    _update_text()
    if count > 10: color_label()

func color_label():
    var extra_scale = 1
    if font_size == 2: 
        extra_scale = 1.5
    elif font_size == 3: 
        extra_scale = 2
    TwnLite.at(label, true, '_twn_scale').tween({
        prop='scale',
        from = Vector2(.9,.9) * randf_range(1.05, 1.08) * get_count_facor_scale(extra_scale), 
        to = Vector2(1, 1) * extra_scale,
        dur = 0.25 * get_count_facor_time(),
        trans=Tween.TRANS_QUAD,
    })
    # TwnLite.at(label).tween({
    #     prop='modulate',
    #     from = _current_color,
    #     to = Color(1, 1, 1),
    #     dur = 2.0 * get_count_facor_time(),
    #     trans=Tween.TRANS_QUAD,
    #     ease= Tween.EASE_OUT,
    # }).callee(
    #     _reset_count
    # )
    TwnLite.at(label).tween({
        prop='modulate:a',
        from = 1.0,
        to = 0.0,
        dur = 0.3 * get_count_facor_time(),
        trans=Tween.TRANS_QUAD,
        ease= Tween.EASE_OUT,
    })
    label2.modulate.a = 1.0
    TwnLite.at(label2, true, '_twn_lite_lb2').tween({
        prop='modulate:a',
        from = 1.0,
        to = 0.0,
        dur = 1.0 * get_count_facor_time(),
        trans=Tween.TRANS_SINE,
        ease= Tween.EASE_OUT,
        delay=1.0 * get_count_facor_time(),
    }).callee(
        _reset_count
    )
    TwnLite.at(label3).tween({
        prop='self_modulate:a',
        from = 1.0,
        to = 0.0,
        dur = 0.3 * get_count_facor_time(),
        trans=Tween.TRANS_QUAD,
        ease= Tween.EASE_OUT,
    })
    TwnLite.at(label2).tween({
        # prop='modulate:a',
        # from = 2.0,
        # to = 0.0,
        # dur = 0.3,
        # parallel= true,
        # trans=Tween.TRANS_SINE,
    # }).tween({
        prop='scale',
        from = Vector2(.9,.9) * 1.1 *  get_count_facor_scale(extra_scale),
        to = Vector2(1, 1) * extra_scale,
        dur = 0.26 * get_count_facor_time(),
        parallel=  true,
        trans=Tween.TRANS_EXPO,
    })

func _reset_count():
    count = 0
    _update_text()
    if on_count_reset: on_count_reset.call()

func get_count_facor_scale(extra_scale=1):
    return max(1, min(combo_count, 400) / 100.0 ) * extra_scale
func get_count_facor_time():
    return max(1, (min(combo_count, 400) / 100.0) * 0.5)
