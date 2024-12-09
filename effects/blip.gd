extends Node2D

var destroy: bool = false
var last_key: String = ""
var pitch_increase: float = 0.0
var sound: bool = true
var blips: bool = true

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var gpu_particle_2d: GPUParticles2D = $GPUParticles2D
@onready var timer: Timer = $Timer
@onready var label: Label = $Label

func _ready():
    if sound:
        audio_stream_player.pitch_scale = 1.0 + pitch_increase * 0.01
        audio_stream_player.play()
    
    if blips:
        animated_sprite_2d.frame = 0
        animated_sprite_2d.play("default")
        gpu_particle_2d.emitting = true
    
    timer.start()

    var move_right = false
    if last_key == 'Enter': 
        move_right = true
    if last_key == 'Space':
        label.text = '_'
    elif last_key == 'Enter':
        label.text = 'Enter'
    else:
        label.text = SettingManager.get_key_shown_shift(last_key)

    var clr_to =Color.from_hsv(0.4 + Rnd.rangef(0.2), 0.8, 1.0)
    TwnLite.at(label).tween({
        prop='modulate',
        from=clr_to,
        to=Color('FFFFFF'),
        dur=0.4,
        parallel=true,
    }).tween({
        prop='scale',
        from=Vector2(1, 1),
        to=Vector2(3, 3),
        dur=0.3,
        parallel=true,
    }).tween({
        prop='position',
        from=Vector2(-35+20, -60),
        to=Vector2(-35-80, -110) if !move_right else Vector2(-35+120, -110),
        dur=0.6,
        parallel=true,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_SINE,
    }).tween({
        target=animated_sprite_2d,
        prop='scale',
        from=Vector2(1, 1),
        to=Vector2(5, 5),
        dur=0.6,
        parallel=true,
    }).tween({
        prop='modulate',
        from=Color.WHITE,
        to=Color('FFFFFF00'),
        dur=0.3,
        parallel=true,
        delay=0.6,
    })


func _on_Timer_timeout():
    if destroy:
        queue_free()
