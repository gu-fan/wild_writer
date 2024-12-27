class_name WildEdit extends CodeEdit

var last_key: String = ''

const Blip: PackedScene    = preload("res://effects/blip.tscn")

var effects = {
    level=1,
    combo=1,
    combo_shot=1,
    audio=1,
    shake=1,
    chars=1,
    delete=1,
    newline=1,
    particles=1,
}

var pitch_increase: float = 0.0


func _ready():
    print('WildEdit inited')

    gui_input.connect(_on_gui_input)
    text_changed.connect(_on_text_changed)


func _on_gui_input(event):
    if event is InputEventKey and event.pressed:
        if event.unicode:
            last_key = String.chr(event.unicode)

func _on_text_changed():
    print('key', last_key)
    var pos = _gfcp() 
    var thing = Blip.instantiate()
    thing.pitch_increase = pitch_increase
    pitch_increase += 1.0
    pitch_increase = min(pitch_increase, 999)
    thing.position = pos
    thing.destroy = true
    thing.audio = effects.audio
    thing.blips = effects.particles
    thing.last_key = last_key
    add_child(thing)

func _gfcp():
    var cp = get_caret_draw_pos()
    var lh = get_line_height()
    var c_line = get_caret_line()
    var c_col = get_caret_column()
    if c_col == 0 and c_line != 0: cp.y += lh * 0.45
    cp += Vector2(0,-lh/2.0)
    return cp
