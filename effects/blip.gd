extends Node2D

var destroy=false
var last_key=""
var pitch_increase=0.0
var audio=true
var blips=true

@onready var s=$AudioStreamPlayer
@onready var n=$AnimatedSprite2D
@onready var g=$GPUParticles2D
@onready var t=$Timer
@onready var l=$Label

var char_offset=Vector2.ZERO

func _ready():
    var f=SettingManager.get_basic_setting("font_size")
    var e=1
    if f==2:e=1.5
    elif f==3:e=2
    if audio:s.pitch_scale=1.0+pitch_increase*.01;s.play()
    if blips:
        n.frame=0;n.play("default")
        TwnLite.at(n).tween({prop='modulate:a',from=1.0,to=0.0,dur=0.2,delay=0.2,ease=1,trans=1})
    else:
        n.hide()
    t.start()
    var r=last_key=='Enter'
    if last_key=='Space':l.text='_'
    elif last_key=='Enter':l.text='Enter'
    else:l.text=SettingManager.get_key_shown_shift(last_key)
    var c=Color.from_hsv(0.4+Rnd.rangef(0.2),0.8,1.0)
    TwnLite.at(l).tween({prop='modulate',from=c,to=Color('FFFFFF'),dur=0.4,parallel=true}).tween({prop='scale',from=Vector2(1,1)*e,to=Vector2(3,3)*e,dur=0.3,parallel=true}).tween({prop='position',from=Vector2(-35+20,-60)+char_offset,to=Vector2(-35+140,-110)*e+char_offset if r else Vector2(-35-100,-110)*e+char_offset,dur=0.6,parallel=true,ease=1,trans=1}).tween({target=n,prop='scale',from=Vector2(1,1)*e,to=Vector2(5,5)*e,dur=0.6,parallel=true}).tween({prop='modulate',from=Color.WHITE,to=Color('FFFFFF00'),dur=0.4,parallel=true,delay=0.55})

func _on_Timer_timeout():if destroy:queue_free()
