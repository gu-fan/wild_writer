extends Control
class_name EffectLaser
@onready var timer: Timer = $Timer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var line_2d: Line2D = $Line2D
@onready var circle: Sprite2D = $Circle
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_stream_player_2d2: AudioStreamPlayer2D = $AudioStreamPlayer2D2

var audio: bool = true

var count = 0
const BASE_COUNT = 40
const COUNT_SIZE = {
    40: 1,
    80: 2,
    120: 3,
    160: 4,
    200: 5,
}
const SIZE_DURATION = {
    1: 0.3,
    2: 0.8,
    3: 1.3,
    4: 1.8,
    5: 2.3,
}
const SIZE_POSITION = {
    1: -600,
    2: -300,
    3: 0,
    4: 300,
    5: 600,
}
const SIZE_MIN = {
    1: 300,
    2: 500,
    3: 700,
    4: 900,
    5: 900,
}

static func can_finish_combo(n: int):
    return n > BASE_COUNT


static func get_main_duration(count):
    var size = get_count_size(count)
    return SIZE_DURATION[size] + 0.4
static func get_count_size(count):
    var target_size = COUNT_SIZE[BASE_COUNT]
    for threshold in COUNT_SIZE:
        if count >= threshold:
            target_size = COUNT_SIZE[threshold]
    return target_size

func _ready():
    var font_size = SettingManager.get_basic_setting("font_size")
    var extra_scale = 1
    if font_size == 2: 
        extra_scale = 1.5
    elif font_size == 3: 
        extra_scale = 2

    shake_intensity = extra_scale * 6

    var target_size = get_count_size(count)
    var len_x = max(size.x + SIZE_POSITION[target_size], SIZE_MIN[target_size])
    var len_y = 40 * target_size * extra_scale
    line_2d.set_point_position(1, Vector2(len_x, 0))
    var ls_dur = SIZE_DURATION[target_size]

    if audio:
        match target_size:
            1: audio_stream_player_2d.pitch_scale = 3.5
            2: audio_stream_player_2d.pitch_scale = 2.5
            3: audio_stream_player_2d.pitch_scale = 2.0
            4: audio_stream_player_2d.pitch_scale = 1.5
            5: audio_stream_player_2d.pitch_scale = 1.0

        audio_stream_player_2d.pitch_scale += randf_range(-0.1, 0.1)
        audio_stream_player_2d.play()
    
    timer.wait_time = ls_dur + 2.0
    timer.start()

    TwnLite.at(line_2d).tween({
        prop='width',
        from=0,
        to=len_y,
        dur=0.4,
    }).delay(
        ls_dur
    ).tween({
        prop='width',
        from=len_y,
        to=0,
        dur=0.4,
    }).callee(line_2d.hide)


    TwnLite.at(animated_sprite_2d).tween({
        prop='scale',
        from=Vector2(1, 1),
        to=Vector2(2, 2) * target_size * extra_scale,
        dur=0.3,
    }).delay(ls_dur+ 0.1).tween({
        prop='scale',
        from=Vector2(2, 2) * target_size * extra_scale,
        to=Vector2(0, 0),
        dur=0.5,
    }).callee(line_2d.hide)

    TwnLite.at(circle).tween({
        prop='scale',
        from = Vector2(0.1, 0.1),
        to= Vector2(target_size*2.5, target_size * 2.5) * extra_scale,
        parallel=true,
        dur=0.2,
        trans=Tween.TRANS_SINE,
        ease=Tween.EASE_OUT,
    }).tween({
        prop='modulate:a',
        from = 1.0,
        to= 0.0,
        dur=0.1,
        delay=0.1,
    })

    if audio and target_size > 1:
        # match target_size:
        #     2: audio_stream_player_2d2.pitch_scale = 1.0
        #     3: audio_stream_player_2d2.pitch_scale = 1.1
        #     4: audio_stream_player_2d2.pitch_scale = 1.2
        #     5: audio_stream_player_2d2.pitch_scale = 1.3

        audio_stream_player_2d2.pitch_scale += randf_range(-0.1, 0.1)
        audio_stream_player_2d2.set('parameters/looping', true)

        get_tree().create_timer(0.2).timeout.connect(audio_stream_player_2d2.play)
        get_tree().create_timer(ls_dur+0.2).timeout.connect(_fade_audio.bind(audio_stream_player_2d2))

func _fade_audio(player):
    TwnLite.at(player).tween({
        prop="volume_db",
        from=0,
        to=-40,
        dur=0.5,
    })


func _on_Timer_timeout():
    queue_free()

var shake_intensity:float  = 5.0
func _process(delta):
    line_2d.position = Vector2(randf_range(-shake_intensity,shake_intensity), randf_range(-shake_intensity,shake_intensity))
