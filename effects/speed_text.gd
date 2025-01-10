extends Control
class_name SpeedText

@onready var label: Label = $Label
@onready var label2: Label = $Label2
@onready var label3: Label = $Label/Label3

var text := ''  :
    set(v):
        label.text = v
        label2.text = v
        label3.text = v
        text = v
var count : float = 0 :
    set(v):
        count = v
        # update_color()
        if template: text = template % count

var template = ''

# 定义颜色阶段
var COMBO_COLORS = {
    0:  Color(0, 1, 0),
    20:  Color(0.5, .8, 0),
    40:  Color(.8, .8, 0),
    60:  Color(.8, 0.5, 0),
    80:  Color(1, 0, 0),
    90: Color(1, 0, 0.5),
    100: Color(1, 0, 1),
}

var _current_color: Color = Color.WHITE

# func _ready():
#     Engine.time_scale = 0.5
#     for i in 10:
#         update_label()
#         await Util.wait(2.0)
#         count = 100
#         update_label()
#         await Util.wait(2.0)
#         count = 200
#         update_label()
#         await Util.wait(2.0)
#         count = 300
#         update_label()
#         await Util.wait(2.0)
#         count = 400
#         update_label()

func update_label():
    # var font_size = SettingManager.get_basic_setting("font_size")
    var extra_scale = 1
    # if font_size == 2: 
    #     extra_scale = 1.5
    # elif font_size == 3: 
    #     extra_scale = 2
    TwnLite.at(label, true, '_twn_scale').tween({
        prop='scale',
        from = Vector2(.9,.9) * randf_range(1.05, 1.1) * get_count_facor_scale(extra_scale), 
        to = Vector2(1, 1) * extra_scale,
        dur = 0.28 * get_count_facor_time(),
        trans=Tween.TRANS_QUAD,
    })
    TwnLite.at(label).tween({
        prop='modulate',
        from = _current_color,
        to = Color(1,1,1),
        dur = 0.28 * get_count_facor_time(),
        trans=Tween.TRANS_QUAD,
        ease= Tween.EASE_OUT,
    })
    TwnLite.at(label3).tween({
        prop='self_modulate:a',
        from = 1.3,
        to = 0.0,
        dur = 0.28 * get_count_facor_time(),
        trans=Tween.TRANS_QUAD,
        ease= Tween.EASE_OUT,
    })
    label2.modulate.a = 1.0
    label2.scale = Vector2.ONE * extra_scale
    TwnLite.at(label2).tween({
        prop='modulate:a',
        from = 2.0,
        to = 0.0,
        dur = 0.3,
        parallel= true,
        trans=Tween.TRANS_SINE,
    }).tween({
        prop='scale',
        from = Vector2(.9,.9) * 1.1 *  get_count_facor_scale(extra_scale),
        to = Vector2(1, 1) * extra_scale * 1.05,
        dur = 0.26 * get_count_facor_time(),
        parallel=  true,
        trans=Tween.TRANS_EXPO,
    })

func get_count_facor_scale(extra_scale=1):
    return max(1, min(count*2, 110) / 100.0 ) * extra_scale
    # return 1
func get_count_facor_time():
    return max(1, (min(count*2, 110) / 100.0) * 0.5)
    # return 0.5

func update_color():
    # 找到当前combo对应的颜色阶段
    var target_color = COMBO_COLORS[0]  # 默认颜色
    for threshold in COMBO_COLORS:
        if count >= threshold:
            target_color = COMBO_COLORS[threshold]
    
    # 平滑过渡到目标颜色
    _current_color = target_color
    label.modulate = _current_color
    label3.modulate = Color(_current_color).lightened(0.2)

func update_color_by_rating(rating:String):
    var score = 0
    match rating:
        'D': score = 40
        'C': score = 60
        'B': score = 80
        'A': score = 90
        'S': score = 100
    count = score
    update_color()
    

# ----------
func set_font_size(v: int):
    # label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    # label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    # label3.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    # UI.set_layout(label, UI.PRESET_TOP_RIGHT)
    # UI.set_layout(label2, UI.PRESET_TOP_RIGHT)
    # label.pivot_offset = Vector2(200, 0)
    # label2.pivot_offset = Vector2(200, 0)
    UI.set_font_size(label, v)
    UI.set_font_size(label2, v)
    UI.set_font_size(label3, v)
