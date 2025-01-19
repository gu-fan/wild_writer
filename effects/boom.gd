extends Node2D

var destroy = false
var last_key = ""
var audio: bool = true
var blips: bool = true
var chars: bool = true

@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var gpu_particle_2d: GPUParticles2D = $GPUParticles2D

var animation = '1'
var particle_scale = 1.0
var sprite_scale = 1.0
var font_size = 1
var font_res = ''
var size_offset = Vector2.ZERO

func _ready():

    timer.start()

    var extra_scale = 1
    if font_size == 0: 
        size_offset = Vector2(0, -5)
    if font_size == 2: 
        extra_scale = 1.5
        size_offset = Vector2(0, -30)
    elif font_size == 3: 
        extra_scale = 2
        size_offset = Vector2(0, -80)

    if audio:
        audio_stream_player.pitch_scale += randf_range(-0.1, 0.1)
        audio_stream_player.play()

    if blips:
        gpu_particle_2d.process_material.scale_min = 4 * extra_scale * particle_scale
        gpu_particle_2d.process_material.scale_max = 4 * extra_scale * particle_scale
        gpu_particle_2d.process_material.initial_velocity_min = 500  + 40 * font_size + 100 * (particle_scale - 1 )
        gpu_particle_2d.process_material.initial_velocity_max = 800 +40 * font_size + 100 * (particle_scale - 1)
        if particle_scale > 1:
            gpu_particle_2d.lifetime = 0.8
        gpu_particle_2d.emitting = true
        animated_sprite_2d.show()
        animated_sprite_2d.frame = 0
        # animated_sprite_2d.play("1")
        animated_sprite_2d.play(animation)
        animated_sprite_2d.scale = Vector2(3, 3) * extra_scale * sprite_scale

    if chars:
        if font_res:
            label.set("theme_override_fonts/font", font_res)
        label.text = last_key
        if last_key == 'Backspace': 
            label.text='←'
        elif last_key == 'Shift+Backspace': 
            label.text='Shift+←'
        elif last_key == 'Option+Backspace': 
            label.text='Option+←'
        elif last_key == 'Alt+Backspace': 
            label.text='Alt+←'
        elif last_key == 'Ctrl+Backspace': 
            label.text='Ctrl+←'
        elif last_key == 'Command+Backspace': 
            label.text='Cmd+←'
        elif last_key == 'Windows+Backspace': 
            label.text='Windows+←'
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
            from=Vector2(-35-20, -60) + size_offset,
            to=Vector2(-35+80, -100)*extra_scale + size_offset,
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
    queue_free()
