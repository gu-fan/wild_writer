extends Node2D

var destroy = false
var last_key = ""
var sound = true

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var gpu_particle_2d: GPUParticles2D = $GPUParticles2D

func _ready():
    if sound:
        audio_stream_player.play()
    
    animated_sprite_2d.frame = 0
    animated_sprite_2d.play("2")
    timer.start()
    label.text = '←'
    gpu_particle_2d.emitting = true

    var clr_to =Color.from_hsv(-0.1 + Rnd.rangef(0.2), 0.8, 1.0)
    TwnLite.at(label).tween({
        prop='modulate',
        from=clr_to,
        to=Color('FFFFFF'),
        dur=0.6,
        parallel=true,
    }).tween({
        prop='scale',
        from=Vector2(1, 1),
        to=Vector2(3, 3),
        dur=0.3,
        parallel=true,
    }).tween({
        prop='position',
        from=Vector2(-35-20, -60),
        to=Vector2(-35+80, -110),
        dur=0.6,
        parallel=true,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_QUAD,
    }).tween({
        prop='modulate',
        from=Color.WHITE,
        to=Color('FFFFFF00'),
        dur=0.2,
        parallel=true,
        delay=0.6,
    })

func _on_Timer_timeout():
    if destroy:
        queue_free()
