class_name FinalWindow extends Window

signal window_canceled

@onready var g_ok: Button = $OK
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var audio_stream_player2: AudioStreamPlayer = $AudioStreamPlayer2
@onready var audio_stream_player3: AudioStreamPlayer = $AudioStreamPlayer3

var viewport
func _ready():
    viewport = get_tree().current_scene.get_viewport()
    viewport.size_changed.connect(_on_viewport_resized)

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
    $MaxCombo.hide()
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
    print('got stats', stats)
    # stats = {
    #     rating_speed = 'S',
    #     rating_style= 'B',
    #     rating_accuracy= 'B',
    #     rating_final = 'A',
    #     }
    var t = 0.3
    t = _trans_in_node_left($BarTop, t)
    t = _trans_in_node_left($Title, t)
    t = _trans_in_node_time($TotalTime, t, 'Total Time: %s', 0, stats.time, 0.6)
    t = _trans_in_node_left($TotalWord, t, 'Total Word: %d', 0, stats.word,0.6)
    t = _trans_in_node_left($MaxCombo, t, 'Max Combo: %d', 0, 199, 0.6) +0.3

    t = _trans_in_node_right($KPM, t, 'KPM: %d', 0, stats.kpm, 0.6)
    t = _trans_in_node_right($WPM, t, 'WPM: %d', 0, stats.wpm, 0.6) + 0.3
    $SpeedRating.text = 'Speed: %s' % stats.rating_speed
    t = _trans_in_rating($SpeedRating, t) + 0.4

    t = _trans_in_node_right($Natural, t, 'Natural: %d', 0, stats.style_scores.natural, 0.6)
    t = _trans_in_node_right($Repeat, t, 'Repeat: %d', 0, stats.style_scores.repeat, 0.6)
    t = _trans_in_node_right($Punctuation, t, 'Punctuation: %d', 0, stats.style_scores.punc, 0.6)
    t = _trans_in_node_right($Rhythm, t, 'Rhythm: %d', 0, stats.style_scores.rhythm, 0.6) + 0.3
    $StyleRating.text = 'Style: %s' % stats.rating_style
    t = _trans_in_rating($StyleRating, t) + 0.4

    t = _trans_in_node_right($Accuracy, t, 'Accuracy: %.1f%%', 0.0, stats.accuracy, 0.6) + 0.3
    $AccuracyRating.text = 'Accuracy: %s' % stats.rating_accuracy
    t = _trans_in_rating($AccuracyRating, t) + 0.4

    t = _trans_in_node_right($BarBottom, t)
    t = _trans_in_node_left($FinalLabel, t) + 0.5
    $FinalRating.text = stats.rating_final
    t = _trans_in_final($FinalRating, t, stats.rating_final)
    # _trans_in_node_left($OK, 3.0)

func _trans_in_node_left(nd, delay=0.0, tpl='', from=0.0, to=1.0, dur=1.0):
    return _trans_in_node(nd, -1, delay, tpl, from, to, dur)

func _trans_in_node_right(nd, delay=0.0, tpl='', from=0.0, to=1.0, dur=1.0):
    return _trans_in_node(nd, 1, delay, tpl, from, to, dur)

func _trans_in_node(nd, dir=1, delay=0.0, tpl='', from=0.0, to=1.0, dur=1.0):
    nd.show()
    nd.modulate.a = 0.0
    var pos_x = Util._get_orig(nd, 'position:x')
    var from_pos_x = pos_x + 20 * dir
    var twn = TwnLite.at(nd)
    twn.tween({
        prop = 'modulate:a',
        from = 0.0, 
        to = 1.0,
        dur=0.2,
        parallel=true,
        delay = delay,
    }).tween({
        prop = 'position:x',
        from = from_pos_x,
        to = pos_x,
        dur=0.2,
        parallel=true,
        delay = delay,
    })
    if tpl:
        twn.follow({call=TwnMisc.of(nd)._follow_number.bind(tpl), from=from, to=to, dur=dur+0.05, delay=delay+0.15, parallel=true})
        Util.wait(delay + 0.15, __play_audio)
        return dur + delay + 0.05
    else:
        return 0.1 + delay

func _trans_in_rating(nd, delay=0.0, rating='A'):
    nd.show()
    nd.modulate.a = 0.0
    var pos_x = Util._get_orig(nd, 'position:x')
    var from_pos_x = pos_x + 50 * -1
    var twn = TwnLite.at(nd)
    twn.tween({
        prop = 'modulate:a',
        from = 0.0, 
        to = 1.0,
        dur=0.2,
        parallel=true,
        delay = delay,
    }).tween({
        prop = 'position:x',
        from = from_pos_x,
        to = pos_x,
        dur=0.3,
        parallel=true,
        delay = delay,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_EXPO,
    }).callee({
        call=nd.update_color_by_rating,
        args=[rating],
        parallel = true,
        delay=delay+0.05,
    }).callee({
        call=nd.update_label,
        parallel = true,
        delay=delay+0.05,
    })
    Util.wait(delay+0.1, __play_audio2)
    return 0.1 + delay

func _trans_in_final(nd, delay=0.0, rating='A'):
    nd.show()
    nd.modulate.a = 0.0
    var _scale_from = Vector2.ONE * 8
    var _scale_to = Vector2.ONE
    nd.scale = _scale_from
    nd.pivot_offset = nd.size / 2.0
    var twn = TwnLite.at(nd)
    twn.tween({
        prop = 'modulate:a',
        from = 0.0, 
        to = 1.0,
        dur=0.2,
        parallel=true,
        delay = delay,
    }).tween({
        prop = 'scale',
        from = _scale_from,
        to = _scale_to,
        dur=0.5,
        parallel=true,
        delay = delay,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_EXPO,
    }).callee({
        call=nd.update_color_by_rating,
        args=[rating],
        parallel = true,
        delay=delay+0.2,
    }).callee({
        call=nd.run_glitch,
        parallel = true,
        delay=delay+0.3,
    })
    Util.wait(delay+0.1, __play_audio3.bind(rating))
    return 0.1 + delay

func _trans_in_bar():
    return 0.1

func _trans_in_node_time(nd, delay=0.0, tpl='', from=0.0, to=1.0, dur=1.0):
    nd.show()
    nd.modulate.a = 0.0
    var pos_x = Util._get_orig(nd, 'position:x')
    var from_pos_x = pos_x + 20 * -1
    var twn = TwnLite.at(nd)
    twn.tween({
        prop = 'modulate:a',
        from = 0.0, 
        to = 1.0,
        dur=0.2,
        parallel=true,
        delay = delay,
    }).tween({
        prop = 'position:x',
        from = from_pos_x,
        to = pos_x,
        dur=0.2,
        parallel=true,
        delay = delay,
    })
    if tpl:
        twn.follow({call=TwnMisc.of(nd)._follow_time.bind(tpl), from=from, to=to, dur=dur+0.05, delay=delay+0.15, parallel=true})
        Util.wait(delay + 0.15, __play_audio)
        return dur + delay + 0.05
    else:
        return 0.1 + delay

func _on_viewport_resized():
    var window_size = Vector2(size)
    var viewport_size = Vector2(get_tree().current_scene.get_viewport_rect().size)
    position = Vector2((viewport_size - window_size) / 2)

func __play_audio():
    if visible: audio_stream_player.play()
func __play_audio2():
    if visible: audio_stream_player2.play()
func __play_audio3(rating='A'):
    if visible:
        match rating:
            'S': audio_stream_player3.pitch_scale = 1.3
            'A': audio_stream_player3.pitch_scale = 1.2
            'B': audio_stream_player3.pitch_scale = 1.1
            'C': audio_stream_player3.pitch_scale = 1.0
        audio_stream_player3.play()
