class_name KeyHint
extends PanelContainer

@onready var label: Label = $Label

func show_sequence(sequence: Array):
    label.text = " ".join(sequence) + "..."
    show()

func clear():
    hide()
