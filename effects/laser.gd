extends Control
class_name EffectLaser
@onready var t=$Timer
@onready var n=$AnimatedSprite2D
@onready var l=$Line2D
@onready var c=$Circle
@onready var a1=$AudioStreamPlayer2D
@onready var a2=$AudioStreamPlayer2D2
var audio=true
var count=0
const B=40
const S={40:1,80:2,120:3,160:4,200:5}
const D={1:.3,2:.8,3:1.3,4:1.8,5:2.3}
const P={1:-600,2:-300,3:0,4:300,5:600}
const M={1:400,2:600,3:800,4:1000,5:1200}
static func can_finish_combo(n):return n>B
static func get_main_duration(count):var s=get_count_size(count);return D[s]+.4
static func get_count_size(count):
    var t=S[B]
    for h in S:
        if count>=h:t=S[h]
    return t
func _ready():
    var f=SettingManager.get_basic_setting("font_size")
    var e=1
    if f==2:e=1.5
    elif f==3:e=2
    k=e*6
    var s=get_count_size(count)
    var x=max(size.x+P[s],M[s])
    var y=40*s*e
    l.set_point_position(1,Vector2(x,0))
    var d=D[s]
    if audio:
        match s:
            1:a1.pitch_scale=3.5
            2:a1.pitch_scale=2.5
            3:a1.pitch_scale=2.0
            4:a1.pitch_scale=1.5
            5:a1.pitch_scale=1.0
        a1.pitch_scale+=randf_range(-.1,.1)
        a1.play()
    t.wait_time=d+2;t.start()
    TwnLite.at(l).tween({prop='width',from=0,to=y,dur=.4}).delay(d).tween({prop='width',from=y,to=0,dur=.4}).callee(l.hide)
    TwnLite.at(n).tween({prop='scale',from=Vector2(1,1),to=Vector2(2,2)*s*e,dur=.3}).delay(d+.1).tween({prop='scale',from=Vector2(2,2)*s*e,to=Vector2.ZERO,dur=.5}).callee(l.hide)
    TwnLite.at(c).tween({prop='scale',from=Vector2(.1,.1),to=Vector2(s*2.5,s*2.5)*e,parallel=true,dur=.2,trans=1,ease=1}).tween({prop='modulate:a',from=1,to=0,dur=.1,delay=.1})
    if audio and s>1:
        a2.pitch_scale+=randf_range(-.1,.1)
        a2.set('parameters/looping',true)
        get_tree().create_timer(.2).timeout.connect(a2.play)
        get_tree().create_timer(d+.2).timeout.connect(_f.bind(a2))
func _f(p):TwnLite.at(p).tween({prop="volume_db",from=0,to=-40,dur=.5})
func _on_Timer_timeout():queue_free()
var k=5.0
func _process(d):l.position=Vector2(randf_range(-k,k),randf_range(-k,k))
