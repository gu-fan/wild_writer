extends Node2D


@onready var editor_man: TinyEditor = $CanvasLayer

var file_manager: FileManager

func _ready():
    file_manager = FileManager.new()
    add_child(file_manager)
    editor_man.file_manager = file_manager
