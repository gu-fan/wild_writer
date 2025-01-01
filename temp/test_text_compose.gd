extends Node2D

# 在其他脚本中使用
@onready var animated_text = $AnimatedText

func _ready():
    animated_text.connect("text_appeared", _on_text_appeared)
    animated_text.connect("text_cleared", _on_text_cleared)
    
    # 设置文本
    animated_text.set_text("Hello World! yes,go 👋 你好\n你好")
    # animated_text.enable_wave = false

func _on_text_appeared():
    print("文本完全显示出来了！")

func _on_text_cleared():
    print("文本完全清除了！")
