extends Node2D

var destroy: bool = false
var last_key: String = ""
var pitch_increase: float = 0.0
var audio: bool = true
var blips: bool = true

@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var gpu_particle_2d: GPUParticles2D = $GPUParticles2D
@onready var timer: Timer = $Timer

var char_offset: Vector2 = Vector2.ZERO
var font_size = 1

func _ready():

    var extra_scale = 1
    if font_size == 2: 
        extra_scale = 1.5
    elif font_size == 3: 
        extra_scale = 2

    if audio:
        # audio_stream_player.stream = load(Rnd.pick(['res://temp/sfx/punch1.ogg', 'res://temp/sfx/punch2.ogg','res://temp/sfx/punch3.ogg']))
        # audio_stream_player.pitch_scale = 1.0 + pitch_increase * 0.01
        audio_stream_player.pitch_scale = 1.2 + Rnd.rangef(-0.02, 0.02)
        audio_stream_player.play()
    
    if blips:
        animated_sprite_2d.frame = 0
        animated_sprite_2d.play("default")
        gpu_particle_2d.emitting = true
        gpu_particle_2d.process_material.scale_min = 4 * extra_scale
        gpu_particle_2d.process_material.scale_max = 4 * extra_scale
        gpu_particle_2d.process_material.initial_velocity_min = 300 + 25 * font_size
        gpu_particle_2d.process_material.initial_velocity_max = 400 + 25 * font_size

        TwnLite.at(animated_sprite_2d).tween({
            prop='modulate:a',
            from=1.0,
            to=0.0,
            dur=0.2,
            delay=0.2,
            ease=Tween.EASE_OUT,
            trans=Tween.TRANS_QUAD,
        }).tween({
            target=animated_sprite_2d,
            prop='scale',
            from=Vector2(2, 2)*extra_scale,
            to=Vector2(4, 4)*extra_scale,
            dur=0.6,
            parallel=true,
        })
    else:
        animated_sprite_2d.hide()
    
    timer.start()



func _on_Timer_timeout():
    queue_free()
