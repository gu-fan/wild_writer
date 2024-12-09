extends Node2D

var destroy = false
var last_key = ""
var audio: bool = true

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var gpu_particle_2d: GPUParticles2D = $GPUParticles2D

func _ready():

    var font_size = SettingManager.get_basic_setting("font_size")
    var extra_scale = 1
    if font_size == 2: 
        extra_scale = 1.5
    elif font_size == 3: 
        extra_scale = 2

    if audio:
        audio_stream_player.pitch_scale += randf_range(-0.1, 0.1)
        audio_stream_player.play()
    
    animated_sprite_2d.frame = 0
    animated_sprite_2d.play("1")
    animated_sprite_2d.scale = Vector2(3, 3) * extra_scale
    timer.start()
    label.text = '←'
    gpu_particle_2d.process_material.scale_min = 4 * extra_scale
    gpu_particle_2d.process_material.scale_max = 4 * extra_scale
    gpu_particle_2d.process_material.initial_velocity_min = 700  + 40 * font_size
    gpu_particle_2d.process_material.initial_velocity_max = 1000 +40 * font_size

    gpu_particle_2d.emitting = true

    var clr_to = Color.from_hsv(0.0 + Rnd.rangef(-0.05, 0.05), 0.8, 1.0)
    TwnLite.at(label).tween({
        prop='modulate',
        from=clr_to,
        to=Color('FFFFFF'),
        dur=0.6,
        parallel=true,
    }).tween({
        prop='scale',
        from=Vector2(1, 1)*extra_scale,
        to=Vector2(3, 3)*extra_scale,
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
