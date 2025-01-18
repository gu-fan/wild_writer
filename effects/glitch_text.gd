extends Control
class_name GlitchText

@onready var label: Label = $Main/Label
@onready var main: Control = $Main
@onready var top: Control = $Top
@onready var bot: Control = $Bot
@onready var label2: Label = $Top/Label
@onready var label3: Label = $Bot/Label
@onready var timer: Timer = $Timer

var font_res = '' : 
    set(v):
        for lb in [label, label2, label3]:
            if v:
                lb.add_theme_font_override('font', v)
            else:
                lb.remove_theme_font_override('font')

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
    90: Color(1, 0, 0.3),
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
    var extra_scale = 1
    # if font_size == 2: 
    #     extra_scale = 1.5
    # elif font_size == 3: 
    #     extra_scale = 2
    # TwnLite.at(label, true, '_twn_scale').tween({
    #     prop='scale',
    #     from = Vector2(.9,.9) * randf_range(1.05, 1.1) * get_count_facor_scale(extra_scale), 
    #     to = Vector2(1, 1) * extra_scale,
    #     dur = 0.28 * get_count_facor_time(),
    #     trans=Tween.TRANS_QUAD,
    # })
    # TwnLite.at(label).tween({
    #     prop='modulate',
    #     from = _current_color,
    #     to = Color(1,1,1),
    #     dur = 0.28 * get_count_facor_time(),
    #     trans=Tween.TRANS_QUAD,
    #     ease= Tween.EASE_OUT,
    # })
    # TwnLite.at(label3).tween({
    #     prop='self_modulate:a',
    #     from = 1.3,
    #     to = 0.0,
    #     dur = 0.28 * get_count_facor_time(),
    #     trans=Tween.TRANS_QUAD,
    #     ease= Tween.EASE_OUT,
    # })
    # prints('update label', label, _current_color, get_count_facor_scale(extra_scale))
    # label2.modulate.a = 1.0
    # label2.scale = Vector2.ONE * extra_scale
    # TwnLite.at(label2).tween({
    #     prop='modulate:a',
    #     from = 2.0,
    #     to = 0.0,
    #     dur = 0.3,
    #     parallel= true,
    #     trans=Tween.TRANS_SINE,
    # }).tween({
    #     prop='scale',
    #     from = Vector2(.9,.9) * 1.1 *  get_count_facor_scale(extra_scale),
    #     to = Vector2(1, 1) * extra_scale * 1.05,
    #     dur = 0.26 * get_count_facor_time(),
    #     parallel= true,
    #     trans=Tween.TRANS_EXPO,
    # })
    var dur = Rnd.rangef(0.05, 0.1)
    var dir = 1 if Rnd.is_true() else -1
    var dis = Rnd.range(10, 30) * dir
    TwnLite.at(label).tween({
        prop='position:x',
        from= 0,
        to = -dis/2,
        dur=dur,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_EXPO,
    }).tween({
        prop='position:x',
        from = -dis/2,
        to = 0,
        dur=dur+0.08,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_EXPO,
    })
    TwnLite.at(top).tween({
        prop='position:x',
        from= 0,
        to = -dis,
        dur=dur,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_EXPO,
    }).tween({
        prop='position:x',
        from = -dis,
        to = 0,
        dur=dur+0.08,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_EXPO,
    })
    TwnLite.at(bot).tween({
        prop='position:x',
        from= 0,
        to = dis / 8,
        dur=dur,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_EXPO,
    }).tween({
        prop='position:x',
        from = dis / 8,
        to = 0,
        dur=dur+0.08,
        ease=Tween.EASE_OUT,
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
    label2.modulate = _current_color
    label3.modulate = _current_color

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
    UI.set_font_size(label, v)
    UI.set_font_size(label2, v)
    UI.set_font_size(label3, v)

# ----------
func _ready():
    timer.timeout.connect(loop_glitch)
func run_glitch():
    is_glitch = true
    timer.start()
    shake_intensity = count / 20.0 + 1.0
    update_label()
    set_process(true)

func loop_glitch():
    timer.wait_time = Rnd.range(0.3, 1.2)
    update_label()
func stop_glitch():
    timer.stop()
    is_glitch = false
    main.position = Vector2.ZERO
    set_process(false)

var is_glitch := false
var shake_intensity:float  = 5.0
func _process(delta):
    if is_glitch:
        main.position = Vector2(randf_range(-shake_intensity,shake_intensity), randf_range(0,0))
