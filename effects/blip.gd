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
@onready var label: Label = $Label

var char_offset: Vector2 = Vector2.ZERO

func _ready():

    var font_size = SettingManager.get_basic_setting("font_size")
    var extra_scale = 1
    if font_size == 2: 
        extra_scale = 1.5
    elif font_size == 3: 
        extra_scale = 2

    if audio:
        audio_stream_player.stream = load(Rnd.pick(['res://temp/sfx/punch1.ogg', 'res://temp/sfx/punch2.ogg','res://temp/sfx/punch3.ogg']))
        # audio_stream_player.pitch_scale = 1.0 + pitch_increase * 0.01
        audio_stream_player.pitch_scale = 1.0 + Rnd.rangef(-0.1, 0.1)
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
        })
    else:
        animated_sprite_2d.hide()
    
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

    label.set("theme_override_font_sizes/font_size", 96)

    var clr_to =Color.from_hsv(0.4 + Rnd.rangef(0.2), 0.8, 1.0)
    TwnLite.at(label).tween({
        prop='modulate',
        from=clr_to,
        to=Color('FFFFFF'),
        dur=0.4,
        parallel=true,
    }).tween({
        prop='scale',
        from=Vector2(.3, .3)*extra_scale,
        to=Vector2(1, 1)*extra_scale,
        dur=0.3,
        parallel=true,
    }).tween({
        prop='position',
        from=Vector2(-35+20, -60) + char_offset,
        to=Vector2(-35-150, -110)*extra_scale + char_offset if !move_right else Vector2(-35+200, -110)*extra_scale + char_offset,
        dur=0.9,
        parallel=true,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_SINE,
    }).tween({
        target=animated_sprite_2d,
        prop='scale',
        from=Vector2(1, 1)*extra_scale,
        to=Vector2(5, 5)*extra_scale,
        dur=0.6,
        parallel=true,
    }).tween({
        prop='modulate',
        from=Color.WHITE,
        to=Color('FFFFFF00'),
        dur=0.5,
        parallel=true,
        delay=0.45,
    })


func _on_Timer_timeout():
    if destroy:
        queue_free()
