extends Node2D

var destroy = false
var blips = true

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

var last_key = ''
var caret_col = 0

func _ready():
    if blips:
        animated_sprite_2d.frame = 0
        animated_sprite_2d.play("1")
        if caret_col > 0:
            animated_sprite_2d.position = Vector2(90, -4)
            animated_sprite_2d.rotation_degrees = 90

    timer.start()


func _on_Timer_timeout():
    if destroy:
        queue_free()
