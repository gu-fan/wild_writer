extends PanelContainer

@onready var label: Label = $Label
var font_res = ''


func _ready():
    if font_res:
        label.set("theme_override_fonts/font", font_res)

var text := '' :
    set(v):
        label.text = v
