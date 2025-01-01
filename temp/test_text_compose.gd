extends Control

# 在其他脚本中使用
@onready var animated_text = $AnimatedText

func _ready():
    animated_text.connect("text_appeared", _on_text_appeared)
    animated_text.connect("text_cleared", _on_text_cleared)
    
    # 设置文本
    animated_text.set_text("Hello World! yes,go 👋 你好 你好")
    animated_text.enable_shake = false
    # animated_text.enable_wave = false

    $BtnTest.pressed.connect(_changed_text)
    $BtnRainbow.pressed.connect(setup_custom_rainbow)

    # 开启彩虹效果
    animated_text.enable_rainbow = true
    animated_text.rainbow_speed = 1.0  # 调整颜色变化速度
    animated_text.rainbow_phase = 0.1  # 调整字符间的颜色差异

func _on_text_appeared():
    print("文本完全显示出来了！")

func _on_text_cleared():
    print("文本完全清除了！")

func _changed_text():
    var txt = Rnd.pick([
            "Hello Worl! ",
            "Pello Worl! ",
            "Helkg Dola!",
            "Hello World! yes",
            "Hello World! yes,go 👋 你好 你好",
            "你好 你好",
        ])
    animated_text.set_text(txt)

# 高级使用
func setup_custom_rainbow():
    animated_text.set_text("Custom Rainbow!")
    for i in animated_text.get_children():
        if i is AnimatedText.CharNode:
            i.enable_rainbow = true
            i.rainbow_speed = 2.0
            i.rainbow_saturation = 0.9  # 更鲜艳的颜色
            i.rainbow_value = 1.0       # 最大亮度
