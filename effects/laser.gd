extends Control
@onready var timer: Timer = $Timer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var line_2d: Line2D = $Line2D
@onready var circle: Sprite2D = $Circle

var count = 0
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


func _get_count_size():
    var target_size = COUNT_SIZE[40]
    for threshold in COUNT_SIZE:
        if count >= threshold:
            target_size = COUNT_SIZE[threshold]
    return target_size


func _ready():
    var target_size = _get_count_size()
    var len_x = max(size.x + SIZE_POSITION[target_size], SIZE_MIN[target_size])
    var len_y = 40 * target_size
    line_2d.set_point_position(1, Vector2(len_x, 0))
    var ls_dur = SIZE_DURATION[target_size]

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
        to=Vector2(2, 2) * target_size,
        dur=0.3,
    }).delay(ls_dur+ 0.1).tween({
        prop='scale',
        from=Vector2(2, 2) * target_size,
        to=Vector2(0, 0),
        dur=0.5,
    }).callee(line_2d.hide)

    TwnLite.at(circle).tween({
        prop='scale',
        from = Vector2(0.1, 0.1),
        to= Vector2(target_size*2.5, target_size * 2.5),
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

func _on_Timer_timeout():
    queue_free()

var shake_intensity:float  = 10.0
func _process(delta):
    line_2d.position = Vector2(randf_range(-shake_intensity,shake_intensity), randf_range(-shake_intensity,shake_intensity))
