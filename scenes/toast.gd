extends PanelContainer

@onready var label: Label = $Label

var text := '' :
    set(v):
        label.text = v
