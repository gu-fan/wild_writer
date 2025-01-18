class_name CreativeModeView
extends Control

signal combo_rating_changed

@onready var creative_mode: CreativeMode = $CreativeMode

@onready var goal_window: GoalWindow = $GoalPanel
@onready var g_1: Button = $GoalPanel/Box/G1
@onready var g_2: Button = $GoalPanel/Box/G2
@onready var g_3: Button = $GoalPanel/Box/G3
@onready var g_ok: Button = $GoalPanel/OK
@onready var g_label: Control = $GoalPanel/Label

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Control = $ProgressPanel/Label

@onready var stats_panel: Control = $StatsPanel
@onready var stats_label: Label = $StatsPanel/Label
@onready var s_wpm: Control = $StatsPanel/WPM
@onready var s_kpm: Control = $StatsPanel/KPM
@onready var stats_detail_panel: Control = $StatsDetail
@onready var stats_detail_label: Label = $StatsDetail/Label
@onready var combo_panel: Control = $ComboPanel
@onready var combo_label: Label = $ComboPanel/Label
@onready var combo_detail_panel: Control = $ComboDetail
@onready var combo_detail_label: Label = $ComboDetail/Label

@onready var c_speed: Control = $ComboPanel/Speed
@onready var c_style: Control = $ComboPanel/Style
@onready var c_accuracy: Control = $ComboPanel/Accuracy

@onready var final_window: FinalWindow = $FinalPanel
@onready var final_close: Button = $FinalPanel/OK

var font_res_ui = '' :
    set(v):
        for lb in [goal_window, final_window]:
            lb.font_res = v

var font_res_fx = '' :
    set(v):
        for lb in [s_wpm, s_kpm, c_speed, c_style, c_accuracy, progress_label]:
            lb.font_res = v

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
    goal_window.hide()
    progress_bar.hide()

    progress_bar.value_changed.connect(_on_progress_changed)
    progress_label.text = ''

    stats_panel.hide()
    stats_detail_panel.hide()
    combo_panel.hide()
    combo_detail_panel.hide()
    final_window.hide()

    g_label.focus_mode = Control.FOCUS_ALL
    goal_window.window_canceled.connect(_on_goal_canceled)

    s_wpm.template = "WPM: %d"
    s_kpm.template = "KPM: %d"
    s_wpm.count = 0
    s_kpm.count = 0
    s_kpm.COMBO_COLORS = {
        # 0:    Color(0, 1, 0),
        # 100:  Color(0.5, 1, 0),
        # 200:  Color(1, 1, 0),
        # 300:  Color(1, 0.5, 0),
        # 400:  Color(1, 0, 0),
        # 500:  Color(1, 0, 0.5),
        # 600:  Color(1, 0, 1),
        0:     Color('00FF33'),
        100:   Color('00FF33'),
        200:  Color('99FF00'),
        300:  Color('FF9900'),
        400:  Color('FF3333'),
        500:  Color('FF3399'),
        600:  Color('FF00FF'),
    }

    # c_speed.set_font_size(32)
    # c_style.set_font_size(32)
    # c_accuracy.set_font_size(32)
    _origin_combo_position.speed = c_speed.position
    _origin_combo_position.style = c_style.position
    _origin_combo_position.accuracy = c_accuracy.position
    _origin_combo_text.speed = c_speed
    _origin_combo_text.style = c_style
    _origin_combo_text.accuracy = c_accuracy
    c_speed.modulate.a = 0.0
    c_style.modulate.a = 0.0
    c_accuracy.modulate.a = 0.0

    _origin_stats_position.wpm = s_wpm.position
    _origin_stats_position.kpm = s_kpm.position
    _origin_stats_position.progress = progress_label.position
    _origin_stats_text.wpm = s_wpm
    _origin_stats_text.kpm = s_kpm
    s_wpm.modulate.a = 0.0
    s_kpm.modulate.a = 0.0

    final_window.get_node('Title').focus_mode = Control.FOCUS_ALL
    
    g_label.COMBO_COLORS = {
        # 0:  Color(0, 1, 0),
        # 100:  Color(0, 1, 0),
        # 200:  Color(.8, 0.5, 0),
        # 500: Color(1, 0, 1),
        0:   Color('00FF33'),
        100:  Color('00FF33'),
        200:  Color('FF3300'),
        500: Color('FF00FF'),
    }


func show_goal_window():
    var window_size = Vector2(500, 300)
    var viewport_size = get_viewport_rect().size
    var win_pos = Vector2((viewport_size - window_size) / 2) + Vector2(0, -50)
    var win_rect = Rect2(window_size, win_pos)
    goal_window.popup()
    goal_window.position = win_pos + Vector2(0, -40)
    TwnLite.at(goal_window).tween({prop='position', from=Vector2i(win_pos + Vector2(0, -40)), to = Vector2i(win_pos)})
    # TwnLite.at(goal_window).tween({prop='size', from=Vector2i(window_size*2), to = Vector2i(window_size)})
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
        # g_label.text = 'Goal: %d' % value
        g_label.text = '%d' % value
        g_label.count = value
        g_label.update_color()
        g_label.update_label()

func _on_goal_started():

    Editor.view.post_sub_window_hide()

    creative_mode.start_goal()
    goal_window.hide()
    # progress_bar.show()
    # progress_bar.modulate.a = 0.7
    stats_panel.show()
    stats_detail_panel.show()
    combo_panel.show()
    combo_detail_panel.show()
    progress_label.text = '0%'

    _trans_in_stats_label()

func _on_stats_updated(is_tick:bool) -> void:
    var stats = creative_mode.get_stats()
    
    # 更新进度条
    progress_bar.value = stats.progress * 100
    
    var last_wpm_count = s_wpm.count
    var last_kpm_count = s_kpm.count
    if is_tick:
        TwnLite.at(s_kpm, false, '_twn_num').tween({
            prop='count',
            from = last_kpm_count,
            to = stats.kpm,
            dur= 0.98,
        })
        TwnLite.at(s_wpm, false, '_twn_num').tween({
            prop='count',
            from = last_wpm_count,
            to = stats.wpm,
            dur= 0.98,
        })
    else:
        TwnLite.off(s_kpm, '_twn_num')
        s_kpm.count = stats.kpm
        TwnLite.off(s_wpm, '_twn_num')
        s_wpm.count = stats.wpm
        s_kpm.update_label()
        s_wpm.update_label()

    stats_detail_label.text = """
    accuracy: %.1f%%
    time: %.1f
    key: %.1f
    word: %.1f
    delete: %.1f
    """ % [stats.accuracy, stats.time, stats.key, stats.word, stats.delete]

func _on_combo_updated():
    var ps = creative_mode.paragraph_stats

    c_speed.text = 'Speed: %s' % ps.rating_speed
    c_style.text = 'Style: %s' % ps.rating_style
    c_accuracy.text = 'Accuracy: %s' % ps.rating_accuracy

    # c_speed.update_color_by_rating(ps.rating_speed)
    # c_speed.update_label()
    # c_style.update_color_by_rating(ps.rating_style)
    # c_style.update_label()
    # c_accuracy.update_color_by_rating(ps.rating_accuracy)
    # c_accuracy.update_label()
    # Util.pos_x_inv_in(c_speed, 0.0)
    # Util.pos_x_inv_in(c_style, 0.1)
    # Util.pos_x_inv_in(c_accuracy, 0.2)
    # Util.pos_x_out(c_speed, 2.0)
    # Util.pos_x_out(c_style, 2.1)
    # Util.pos_x_out(c_accuracy, 2.2)
    _trans_in_combo_rating({speed=ps.rating_speed,style=ps.rating_style,accuracy=ps.rating_accuracy})

    combo_detail_label.text = """
    natural: %.1f
    repeat: %.1f
    punctuation: %.1f
    rhythm: %.1f
    style final: %.1f
    """ % [ps.score_natural, ps.score_repeat, ps.score_punc, ps.score_rhythm, ps.score_style]

func _on_goal_reached() -> void:
    print('goal reached')
    # progress_bar.modulate.a = 1.0

func _on_goal_finished() -> void:
    progress_bar.hide()
    stats_panel.hide()
    stats_detail_panel.hide()
    combo_panel.hide()
    combo_detail_panel.hide()
    progress_label.text = ''
    
    # 显示最终评分面板
    var window_size = Vector2(700, 650)
    var viewport_size = get_viewport_rect().size
    # var win_pos = Vector2((viewport_size - window_size) / 2) + Vector2(0, -50)
    var win_pos = Vector2((viewport_size - window_size) / 2)
    final_window.show()
    final_window.position = win_pos + Vector2(0, -40)
    TwnLite.at(final_window).tween({prop='position', from=Vector2i(win_pos + Vector2(0, -40)), to = Vector2i(win_pos)})
    final_window.reset_stats()

    # final_window.get_node("SpeedRating").text = "Speed: %s" % stats.speed_rating
    # final_window.get_node("StyleRating").text = "Style: %s" % stats.style_rating
    # final_window.get_node("AccuracyRating").text = "Accuracy: %s" % stats.accuracy_rating

    await get_tree().process_frame
    Editor.view.pre_sub_window_show()
    final_window.get_node('Title').grab_focus()
    var stats = creative_mode.get_stats()
    final_window.start_loading_stats(stats)

func _on_final_close_pressed() -> void:
    final_window.hide()
    await get_tree().process_frame
    Editor.view.post_sub_window_hide()

var _origin_combo_position = {
    speed = Vector2.ZERO,
    style = Vector2.ZERO,
    accuracy = Vector2.ZERO,
}
var _origin_combo_text = {
    speed = null,
    style = null,
    accuracy = null,
}
func _trans_in_combo_rating(ratings):
    combo_rating_changed.emit(true)
    Util.wait_call(1.3, combo_rating_changed.emit.bind(false))
    var i = 0
    for s in ['speed', 'style', 'accuracy']:
        var lb = _origin_combo_text[s]
        var pos = _origin_combo_position[s]
        var rating = ratings[s]
        var alpha = 0.0 if lb.modulate.a == 0.0 else lb.modulate.a
        var o_pos_x = pos.x + 10 if alpha == 0.0 else lb.position.x
        TwnLite.at(lb).tween({
            prop='modulate:a',
            from = alpha, 
            to = 1.0,
            dur=0.08,
            parallel= true,
            delay = i * 0.1,
        }).callee({
            call=lb.update_color_by_rating,
            args=[rating],
            parallel = true,
            delay=i*0.1,
        }).callee({
            call=lb.update_label,
            parallel = true,
            delay=i*0.1,
        }).tween({
            prop='position:x',
            from = o_pos_x,
            to = pos.x,
            dur=0.08,
            parallel= true,
            delay = i * 0.1,
        }).tween({
            prop='position:x',
            to = pos.x + 20, 
            from = pos.x,
            dur=0.2,
            parallel= true,
            delay=1.2 + i*0.1,
        }).tween({
            prop='modulate:a',
            to = 0.0, 
            from = 1.0,
            dur=0.2,
            parallel= true,
            delay=1.2 + i*0.1,
        })

        i += 1

# --------------
var _origin_stats_position = {
    wpm = Vector2.ZERO,
    kpm = Vector2.ZERO,
}
var _origin_stats_text = {
    wpm = null,
    kpm = null,
}
func _trans_in_stats_label():
    # stats_panel.modulate.a = 0.5
    s_wpm.modulate.a = 0.0
    s_kpm.modulate.a = 0.0
    var i = 0
    for s in ['kpm', 'wpm']:
        var lb = _origin_stats_text[s]
        var pos = _origin_stats_position[s]
        var alpha = 0.0
        var o_pos_x = pos.x - 30
        TwnLite.at(lb).tween({
            prop='modulate:a',
            from = alpha, 
            to = 1.0,
            dur=0.2,
            parallel= true,
            delay = i * 0.15 + 0.1,
        }).tween({
            prop='position:x',
            from = o_pos_x,
            to = pos.x,
            dur=0.2,
            parallel= true,
            delay = i * 0.15 + 0.1,
        })
        print('lb', lb.modulate.a)

        i += 1

    i = 2
    progress_label.modulate.a = 0.0
    var lb = progress_label 
    var pos = _origin_stats_position.progress
    var alpha = 0.0
    var o_pos_x = pos.x + 30
    TwnLite.at(lb).tween({
        prop='modulate:a',
        from = alpha, 
        to = 1.0,
        dur=0.2,
        parallel= true,
        delay = i * 0.15 + 0.1,
    }).tween({
        prop='position:x',
        from = o_pos_x,
        to = pos.x,
        dur=0.2,
        parallel= true,
        delay = i * 0.15 + 0.1,
    })

func _on_progress_changed(v:float):
    progress_label.text = '%d%%' % int(v)
    progress_label.count = int(v)
    progress_label.update_color()
    progress_label.update_label()
