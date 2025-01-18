extends Node2D

var destroy = false
var last_key = ""
var audio: bool = true
var blips: bool = true
var chars: bool = false

@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var circle: Sprite2D= $Circle
@onready var gpu_particle_2d: GPUParticles2D = $GPUParticles2D

var animation = '2'
var particle_scale = 3.0
var sprite_scale = 3.0
var font_size = 1
var font_res = ''

func _ready():

    timer.start()

    var extra_scale = 1
    if font_size == 2: 
        extra_scale = 1.5
    elif font_size == 3: 
        extra_scale = 2

    if blips:
        TwnLite.at(circle).tween({
            prop='self_modulate:a',
            from=1.0,
            to=0.0,
            dur=0.12,
            parallel=true,
            ease=Tween.EASE_IN,
            trans=Tween.TRANS_QUAD,
        # }).tween({
        #     prop='modulate',
        #     from=Color('33FFFF'),
        #     to=Color('FF3333'),
        #     dur=0.13,
        #     parallel=true,
        }).tween({
            prop='scale',
            from=Vector2(3, 3)*extra_scale,
            to=Vector2(1, 1)*extra_scale,
            dur=0.14,
            parallel=true,
            ease=Tween.EASE_OUT,
            trans=Tween.TRANS_QUAD,
        })
        Util.wait(0.08, _play_animation.bind(font_size, extra_scale))
    else:
        circle.modulate.a = 0

    if chars:
        if font_res:
            label.set("theme_override_fonts/font", font_res)
        label.text = last_key
        if last_key == 'Backspace': 
            label.text='←'
        if last_key == 'Ctrl+X':
            label.hide()
            return
        var clr_to = Color.from_hsv(0.0 + Rnd.rangef(-0.05, 0.05), 0.8, 1.0)
        TwnLite.at(label).tween({
            prop='modulate',
            from=clr_to,
            to=Color('FFFFFF'),
            dur=0.6,
            parallel=true,
        }).tween({
            prop='scale',
            from=Vector2(.3, .3)*extra_scale,
            to=Vector2(1, 1)*extra_scale,
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
            dur=0.3,
            parallel=true,
            delay=0.5,
        })
    else:
        label.hide()

func _on_Timer_timeout():
    if destroy:
        queue_free()

func _play_animation(font_size, extra_scale):
    animated_sprite_2d.show()
    animated_sprite_2d.frame = 0
    animated_sprite_2d.play(animation)
    animated_sprite_2d.scale = Vector2(4, 4) * extra_scale * sprite_scale

    gpu_particle_2d.process_material.scale_min = 4 * extra_scale * particle_scale
    gpu_particle_2d.process_material.scale_max = 4 * extra_scale * particle_scale
    gpu_particle_2d.process_material.initial_velocity_min = 1100  + 40 * font_size + 100 * (particle_scale - 1 )
    gpu_particle_2d.process_material.initial_velocity_max = 1400 + 40 * font_size + 100 * (particle_scale - 1)
    if particle_scale > 1:
        gpu_particle_2d.lifetime = 0.9
    gpu_particle_2d.emitting = true

    if audio:
        audio_stream_player.pitch_scale += randf_range(-0.1, 0.1)
        audio_stream_player.play()
