class_name CreativeModeView
extends Control

@onready var goal_input: SpinBox = $GoalPanel/GoalInput
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var stats_label: Label = $StatsPanel/Label
@onready var detail_label: Label = $DetailPanel/Label
@onready var combo_label: Label = $ComboRating/Label
@onready var rating_panel: Panel = $RatingPanel
@onready var close_button: Button = $RatingPanel/CloseButton

@onready var creative_mode: CreativeMode = $CreativeMode

func _ready() -> void:
    
    creative_mode.stats_updated.connect(_on_stats_updated)
    creative_mode.combo_updated.connect(_on_combo_updated)
    creative_mode.goal_reached.connect(_on_goal_reached)
    
    # 初始化目标输入
    goal_input.value = creative_mode.typing_goal
    goal_input.value_changed.connect(_on_goal_changed)
    
    # 连接关闭按钮
    close_button.pressed.connect(_on_close_button_pressed)
    # 初始隐藏评分面板
    rating_panel.hide()

func set_goal(value):
    goal_input.value = value
    # creative_mode.set_goal(int(value))

func _on_goal_changed(value: float) -> void:
    creative_mode.set_goal(int(value))

func _on_stats_updated() -> void:
    var stats = creative_mode.get_stats()
    
    # 更新进度条
    progress_bar.value = stats.progress * 100
    
    # 更新统计信息
    stats_label.text = """
    WPM: %.1f
    KPM: %.1f
    Accuracy: %.1f%%
    """ % [stats.wpm, stats.kpm, stats.accuracy]

    detail_label.text = """
    time: %.1f
    key: %.1f
    word: %.1f
    delete: %.1f
    """ % [stats.time, stats.key, stats.word, stats.delete]

func _on_combo_updated():
    var ps = creative_mode.paragraph_stats
    print('got styles', ps)
    combo_label.text = """
    Speed: %s
    Style: %s
    Accuracy: %s
    """ % [ps.rating_speed, ps.rating_style, ps.rating_accuracy]

func _on_goal_reached() -> void:
    var stats = creative_mode.get_stats()
    
    # 显示最终评分面板
    rating_panel.show()
    rating_panel.get_node("SpeedRating").text = "Speed: %s" % stats.speed_rating
    rating_panel.get_node("StyleRating").text = "Style: %s" % stats.style_rating
    rating_panel.get_node("AccuracyRating").text = "Accuracy: %s" % stats.accuracy_rating

func _on_close_button_pressed() -> void:
    rating_panel.hide()
