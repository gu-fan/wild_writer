extends Control

var shake: float = 0.0
var count: float = 0
var combo_count : float = 0 : 
    get:
        return count - 10

@onready var label: Label = $Label
@onready var label2: Label = $Label2
@onready var label3: Label = $Label/Label3

# 定义颜色阶段
const COMBO_COLORS = {
    0:   Color(0.5, 1, 0.5),
    8:   Color(0.3, 1, 0.3),
    15:  Color(0, 1, 0),
    30:  Color(1, 1, 0),
    45:  Color(1, 0.7, 0),
    60:  Color(1, 0.5, 0),
    80:  Color(1, 0.2, 0),
    100: Color(1, 0, 0),
    150: Color(1, 0, 0.5),
    200: Color(1, 0, 1),
}

# 当前颜色
var _current_color: Color = Color.WHITE
func _ready():
    var font_size = SettingManager.get_basic_setting("font_size")
    var extra_scale = 1
    if font_size == 2: 
        extra_scale = 1.5
    elif font_size == 3: 
        extra_scale = 2

    label.scale =  Vector2.ONE * extra_scale
    label2.scale =  Vector2.ONE * extra_scale

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
    # 找到当前combo对应的颜色阶段
    var target_color = COMBO_COLORS[0]  # 默认颜色
    for threshold in COMBO_COLORS:
        if combo_count >= threshold:
            target_color = COMBO_COLORS[threshold]
    
    # 平滑过渡到目标颜色
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
    var font_size = SettingManager.get_basic_setting("font_size")
    var extra_scale = 1
    if font_size == 2: 
        extra_scale = 1.5
    elif font_size == 3: 
        extra_scale = 2
    TwnLite.at(label, true, '_twn_scale').tween({
        prop='scale',
        from = Vector2(.8,.8) * randf_range(1.05, 1.1) * get_count_facor_scale(extra_scale), 
        to = Vector2(1, 1) * extra_scale,
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
    TwnLite.at(label3).tween({
        prop='self_modulate:a',
        from = 1.0,
        to = 0.0,
        dur = 2.0 * get_count_facor_time(),
        trans=Tween.TRANS_QUAD,
        ease= Tween.EASE_OUT,
    })
    TwnLite.at(label2).tween({
        prop='modulate:a',
        from = 2.0,
        to = 0.0,
        dur = 0.3,
        parallel= true,
        trans=Tween.TRANS_SINE,
    }).tween({
        prop='scale',
        from = Vector2(.8,.8) * 1.1 *  get_count_facor_scale(extra_scale),
        to = Vector2(1, 1) * extra_scale,
        dur = 0.2 * get_count_facor_time(),
        parallel=  true,
        trans=Tween.TRANS_EXPO,
    })

func _reset_count():
    count = 0
    _update_text()

func get_count_facor_scale(extra_scale=1):
    return max(1, min(combo_count, 400) / 100.0 ) * extra_scale
func get_count_facor_time():
    return max(1, (min(combo_count, 400) / 100.0) * 0.5)
