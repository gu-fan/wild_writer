extends Node2D
var destroy=false
var last_key=""
var audio=true
var blips=true
var chars=true
@onready var s=$AudioStreamPlayer
@onready var n=$AnimatedSprite2D
@onready var t=$Timer
@onready var l=$Label
@onready var g=$GPUParticles2D
func _ready():
    t.start()
    var f=SettingManager.get_basic_setting("font_size")
    var e=1
    if f==2:e=1.5
    elif f==3:e=2
    if audio:
        s.pitch_scale+=randf_range(-.1,.1)
        s.play()
    if blips:
        g.process_material.scale_min=4*e
        g.process_material.scale_max=4*e
        g.process_material.initial_velocity_min=700+50*f
        g.process_material.initial_velocity_max=1000+50*f
        g.emitting=1
        n.show()
        n.frame=0
        n.play("1")
        n.scale=Vector2(3,3)*e
        TwnLite.at(n).tween({prop='modulate:a',from=1.0,to=0.0,dur=0.29+randf_range(-0.04,0.04),ease=0,trans=2})

    if chars:
        l.text = last_key
        if last_key == 'Backspace': 
            l.text='←'
        if last_key == 'Ctrl+X':
            l.hide()
            return
        var c=Color.from_hsv(randf_range(-.05,.05),0.8,1)
        TwnLite.at(l).tween({prop='modulate',from=c,to=Color('FFFFFF'),dur=.6,parallel=true}).tween({prop='scale',from=Vector2(1,1)*e,to=Vector2(3,3)*e,dur=.3,parallel=true}).tween({prop='position',from=Vector2(-55,-60),to=Vector2(45,-110),dur=.6,parallel=true,ease=1,trans=1}).tween({prop='modulate',from=Color.WHITE,to=Color('FFFFFF00'),dur=.2,parallel=true,delay=.6})
    else:
        l.hide()
func _on_Timer_timeout():if destroy:queue_free()
