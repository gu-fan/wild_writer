extends Control

var shake: float = 0.0
var count: float = 0
var combo_count : float = 0 : 
    get:
        return count - 10

@onready var l: Label = $Label
@onready var l2: Label = $Label2
@onready var l3: Label = $Label/Label3


# 定义颜色阶段
const C = {
    0:   Color(0.5, 1, 0.5),
    10:  Color(0.3, 1, 0.3),
    20:  Color(0, 1, 0),
    40:  Color(1, 1, 0),
    80:  Color(1, 0.5, 0),
    120: Color(1, 0, 0),
    160: Color(1, 0, 0.5),
    200: Color(1, 0, 1),
}

# 当前颜色
var _c: Color = Color.WHITE
func _ready():
    var f = SettingManager.get_basic_setting("font_size")
    var e = 1
    if f == 2: 
        e = 1.5
    elif f == 3: 
        e = 2

    l.scale = Vector2(2, 2) * e
    l2.scale = Vector2(2, 2) * e

func _u():
    if count <= 10:
        l.hide()
        l2.hide()
        l3.hide()
    else:
        l.show()
        l2.show()
        l3.show()
        var t = 'Combo x%d' % max(min(combo_count, 999), 0)
        l.text = t
        l2.text = t
        l3.text = t
        _uc()

func _uc():
    var t = C[0]
    for h in C:
        if combo_count >= h:
            t = C[h]
    _c = t
    l.modulate = _c
    l3.modulate = Color(_c).lightened(0.2)

func incr(n=1):
    count += n
    _u()
    if count > 10: _cl()

func decr(n=1):
    count -= n
    _u()
    if count > 10: _cl()

func set_count(n):
    count = n
    _u()
    if count > 10: _cl()

func _cl():
    var f = SettingManager.get_basic_setting("font_size")
    var e = 1
    if f == 2: 
        e = 1.5
    elif f == 3: 
        e = 2
    var g = _gs(e)
    var t = _gt()
    TwnLite.at(l,true,'_twn_scale').tween({prop='scale',from=Vector2(1.6,1.6)*randf_range(1.05,1.15)*g,to=Vector2(2,2)*e,dur=.25*t,trans=1})
    TwnLite.at(l).tween({prop='self_modulate:a',from=1,to=0,dur=2*t,trans=1,ease=1}).callee(_rc)
    TwnLite.at(l3).tween({prop='self_modulate:a',from=1,to=0,dur=2*t,trans=1,ease=1})
    TwnLite.at(l2).tween({prop='modulate:a',from=2,to=0,dur=.3,parallel=true,trans=1}).tween({prop='scale',from=Vector2(1.6,1.6)*1.1*g,to=Vector2(2,2)*e,dur=.2*t,parallel=true,trans=1})

func _rc():
    count = 0
    _u()

func _gs(e=1):
    return max(1, min(combo_count, 400) / 100) * e

func _gt():
    return max(1, (min(combo_count, 400) / 100) * 0.5)
