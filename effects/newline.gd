extends Node2D

var destroy = false
var blips = true

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

var last_key = ''
var caret_col = 0
var font_size = 1

func _ready():
    var extra_scale = 1
    if font_size == 2: 
        extra_scale = 1.5
    elif font_size == 3: 
        extra_scale = 2

    if blips:
        animated_sprite_2d.frame = 0
        animated_sprite_2d.play("1")
        animated_sprite_2d.scale = Vector2(2, 2) * extra_scale
        
        if caret_col > 0:
            animated_sprite_2d.rotation_degrees = 90
            match font_size:
                3: animated_sprite_2d.position.x = 120
                2: animated_sprite_2d.position.x = 100
                _: animated_sprite_2d.position.x = 80
        else:
            match font_size:
                2: animated_sprite_2d.position.x = -90
                3: animated_sprite_2d.position.x = -120
            match font_size:
                0: animated_sprite_2d.position.y = 3
                1: animated_sprite_2d.position.y = 4
                2: animated_sprite_2d.position.y = 4
                3: animated_sprite_2d.position.y = 8


    timer.start()


func _on_Timer_timeout():
    if destroy:
        queue_free()
