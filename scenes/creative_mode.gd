class_name CreativeModeView
extends Control

@onready var creative_mode: CreativeMode = $CreativeMode

@onready var goal_window: GoalWindow = $GoalPanel
@onready var g_1: Button = $GoalPanel/Box/G1
@onready var g_2: Button = $GoalPanel/Box/G2
@onready var g_3: Button = $GoalPanel/Box/G3
@onready var g_ok: Button = $GoalPanel/OK
@onready var g_label: Label = $GoalPanel/Label

@onready var progress_bar: ProgressBar = $ProgressBar

@onready var stats_panel: Panel = $StatsPanel
@onready var stats_label: Label = $StatsPanel/Label
@onready var stats_detail_panel: Panel = $StatsDetail
@onready var stats_detail_label: Label = $StatsDetail/Label
@onready var combo_panel: Panel = $ComboPanel
@onready var combo_label: Label = $ComboPanel/Label
@onready var combo_detail_panel: Panel = $ComboDetail
@onready var combo_detail_label: Label = $ComboDetail/Label

@onready var final_panel: Panel = $FinalPanel
@onready var final_close: Button = $FinalPanel/CloseButton

func _ready() -> void:
    
    creative_mode.goal_new.connect(show_goal_window)
    creative_mode.stats_updated.connect(_on_stats_updated)
    creative_mode.combo_updated.connect(_on_combo_updated)
    creative_mode.goal_reached.connect(_on_goal_reached)
    creative_mode.goal_finished.connect(_on_goal_finished)
    
    # 连接关闭按钮
    final_close.pressed.connect(_on_final_close_pressed)

    g_1.toggled.connect(_on_goal_changed.bind(100))
    g_2.toggled.connect(_on_goal_changed.bind(200))
    g_3.toggled.connect(_on_goal_changed.bind(500))
    g_ok.pressed.connect(_on_goal_started)

    # 初始隐藏评分面板
    final_panel.hide()
    goal_window.hide()
    progress_bar.hide()
    stats_panel.hide()
    stats_detail_panel.hide()
    combo_panel.hide()
    combo_detail_panel.hide()
    final_panel.hide()

    g_label.focus_mode = Control.FOCUS_ALL
    goal_window.window_canceled.connect(_on_goal_canceled)

func show_goal_window():
    goal_window.show()
    await get_tree().process_frame
    Editor.view.pre_sub_window_show()
    g_label.grab_focus()

func _on_goal_canceled():
    goal_window.hide()
    await get_tree().process_frame
    Editor.view.post_sub_window_hide()

func _on_goal_changed(v:bool, value: int) -> void:
    if v:
        creative_mode.set_goal(value)
        g_label.text = 'Goal: %d' % value

func _on_goal_started():
    creative_mode.start_goal()
    goal_window.hide()
    progress_bar.show()
    stats_panel.show()
    # stats_detail_panel.show()
    combo_panel.show()
    # combo_detail_panel.show()


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

    stats_detail_label.text = """
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
    print('goal reached')

func _on_goal_finished() -> void:
    progress_bar.hide()
    stats_panel.hide()
    stats_detail_panel.hide()
    combo_panel.hide()
    combo_detail_panel.hide()

    var stats = creative_mode.get_stats()
    
    # 显示最终评分面板
    final_panel.show()
    final_panel.get_node("SpeedRating").text = "Speed: %s" % stats.speed_rating
    final_panel.get_node("StyleRating").text = "Style: %s" % stats.style_rating
    final_panel.get_node("AccuracyRating").text = "Accuracy: %s" % stats.accuracy_rating

func _on_final_close_pressed() -> void:
    final_panel.hide()
