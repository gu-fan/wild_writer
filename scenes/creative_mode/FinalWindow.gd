class_name FinalWindow extends Window

signal window_canceled

@onready var g_ok: Button = $OK

func _input(event: InputEvent) -> void:
    if not has_focus(): return
    if !is_finished_loading: return

    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            # emit_signal("window_canceled")
            g_ok.pressed.emit()
        if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            g_ok.pressed.emit()

# -------------
var is_finished_loading = false

func reset_stats():
    $Title.hide()
    $BarTop.hide()
    $BarBottom.hide()
    $TotalTime.hide()
    $TotalWord.hide()
    $SpeedRating.hide()
    $KPM.hide()
    $WPM.hide()
    $StyleRating.hide()
    $Natural.hide()
    $Repeat.hide()
    $Punctuation.hide()
    $Rhythm.hide()
    $AccuracyRating.hide()
    $Accuracy.hide()
    $FinalRating.hide()
    $FinalLabel.hide()
    $OK.hide()
func start_loading_stats(stats={}):
    is_finished_loading = false
    Util.wait_set(2.0, self, 'is_finished_loading', true)
    _trans_in_node_left($BarTop, 0.1)
    _trans_in_node_left($Title, 0.3)
    _trans_in_node_left($TotalTime, 0.4)
    _trans_in_node_left($TotalWord, 0.5)
    _trans_in_node_right($KPM, 0.6)
    _trans_in_node_right($WPM, 0.7)
    _trans_in_node_left($SpeedRating, 0.8)
    _trans_in_node_right($Natural, 0.9)
    _trans_in_node_right($Repeat, 1.0)
    _trans_in_node_right($Punctuation, 1.1)
    _trans_in_node_right($Rhythm, 1.2)
    _trans_in_node_left($StyleRating, 1.3)
    _trans_in_node_right($Accuracy, 1.4)
    _trans_in_node_left($AccuracyRating, 1.5)
    _trans_in_node_left($FinalLabel, 1.6)
    _trans_in_node_right($BarBottom, 1.7)
    _trans_in_node_right($FinalRating, 1.8)
    _trans_in_node_left($OK, 2.0)


func _trans_in_node_left(nd, delay=0.0):
    nd.show()
    nd.modulate.a = 0.0
    var pos_x = Util._get_orig(nd, 'position:x')
    var from_pos_x = pos_x - 20
    TwnLite.at(nd).tween({
        prop='modulate:a',
        from = 0.0, 
        to = 1.0,
        dur=0.2,
        parallel= true,
        delay = delay,
    }).tween({
        prop='position:x',
        from = from_pos_x,
        to = pos_x,
        dur=0.2,
        parallel= true,
        delay = delay,
    })
func _trans_in_node_right(nd, delay=0.0):
    nd.show()
    nd.modulate.a = 0.0
    var pos_x = Util._get_orig(nd, 'position:x')
    var from_pos_x = pos_x + 20
    TwnLite.at(nd).tween({
        prop='modulate:a',
        from = 0.0, 
        to = 1.0,
        dur=0.2,
        parallel= true,
        delay = delay,
    }).tween({
        prop='position:x',
        from = from_pos_x,
        to = pos_x,
        dur=0.2,
        parallel= true,
        delay = delay,
    })
func _trans_in_bar():
    pass
