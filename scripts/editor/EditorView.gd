class_name EditorView
extends Control

# TODO:
# DONE subwindow when not focused, escape should also hide it
#   this will contain file_dialog / settings / motion windows ...
#   also when clicing mask, should hide it too (for setting panel)
# DONE fix the font settings
# DONE after reset, we'll met a file open error with empty file
# DONE goal/final window in effect
# ?goal start audio
# DONE blip alter sound 
# ?blip fx random direction
# DONE open dropping file
# DONE pad lines
# DONE toggle debug
# DONE key settings
# DONE mode start / finish logic: toast if not able to start / finish
# Fix font_size positions/sizes (fx, ime display)

# CHECKLIST - font of FX
# BLIP
# BOOM
# BOOMBIG
# Combo
# FireworkProjectile
# AnimatedText
# DUST NO
# LASER NO
# NEWLINE NO

# CHECKLIST - documents
# new
# open
# save
# open_recent
# auto_save
# document_dir

# CHECKLIST - Windows and popups
# File / Directory
# motion
# command
# goal / final
# settings
# KeyCapture

var main
var core: EditorCore
var motions: EditorMotions
var executions: EditorExecutions

const Toast: PackedScene   = preload("res://scenes/toast.tscn")

@onready var split_container: HSplitContainer = $VBoxContainer/MarginContainer/SplitContainer
@onready var primary_container: VBoxContainer = $VBoxContainer/MarginContainer/SplitContainer/PrimaryContainer
@onready var secondary_container: VBoxContainer = $VBoxContainer/MarginContainer/SplitContainer/SecondaryContainer
@onready var text_edit: TextEdit = $VBoxContainer/MarginContainer/SplitContainer/PrimaryContainer/Control/TextEdit
@onready var text_edit_secondary: TextEdit = $VBoxContainer/MarginContainer/SplitContainer/SecondaryContainer/Control/TextEdit
@onready var pad: Control = $VBoxContainer/MarginContainer/SplitContainer/PrimaryContainer/Pad
@onready var pad_secondary: Control = $VBoxContainer/MarginContainer/SplitContainer/SecondaryContainer/Pad

@onready var status: Label = $VBoxContainer/Panel/HBoxContainer/Status
# @onready var debug: Button = $VBoxContainer/Panel/HBoxContainer/Debug
@onready var locale: Button = $VBoxContainer/Panel/HBoxContainer/Locale
@onready var lb_count: Label = $VBoxContainer/Panel/HBoxContainer/Count
@onready var lb_ime: Button = $VBoxContainer/Panel/HBoxContainer/IME
@onready var file: Button = $VBoxContainer/Panel/HBoxContainer/File
@onready var setting: Button = $VBoxContainer/Panel/HBoxContainer/Setting

var timer_fps : Timer = null
@onready var stat_box: VBoxContainer = $StatBox
@onready var log_box: VBoxContainer = $LogBox

var firework

var last_focused_editor: TextEdit = null :
    set(te):
        if last_focused_editor != te:
            if last_focused_editor: last_focused_editor.is_active = false
            last_focused_editor = te
            if last_focused_editor: last_focused_editor.is_active = true
        
var current_motion_window: MotionWindow = null
var current_execution_window: ExecutionWindow = null
var current_file_dialog: FileDialog = null

const AUTOSAVE_INTERVAL = 60.0  # 自动保存间隔（秒）
var autosave_timer: Timer

func init():
    
    core = EditorCore.new()
    add_child(core)
    
    # 初始化命令系统
    motions = EditorMotions.new(self)
    executions =  EditorExecutions.new(self)

    autosave_timer = Timer.new()
    add_child(autosave_timer)
    
    # 初始化视图
    setup_view()
    # 连接信号
    connect_signals()
    # 设置快捷键

    Editor.config = core.config_manager

    # 加载配置
    core.config_manager.load_config()
    core.config_manager.build_ui()

    last_focused_editor = text_edit
    last_focused_editor.document = core.document_manager.new_document()
    
    subscribe_configs()

    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

    await get_tree().create_timer(0.05).timeout

    _preload_effects()

    await get_tree().create_timer(0.1).timeout

    redraw()


    DisplayServer.window_set_drop_files_callback(_on_files_dropped)

    last_focused_editor.call_deferred('grab_focus')

    autosave_timer.timeout.connect(_on_autosave_timeout)
    
func setup_view() -> void:
    text_edit.changed.connect(update_status_bar.bind(text_edit))
    text_edit_secondary.changed.connect(update_status_bar.bind(text_edit_secondary))

    text_edit.pad = pad
    text_edit_secondary.pad = pad_secondary
    
    # 初始隐藏第二编辑器
    secondary_container.hide()


    locale.pressed.connect(toggle_locale)
    setting.pressed.connect(toggle_setting)
    # debug.pressed.connect(toggle_debug)

    timer_fps = Timer.new()
    timer_fps.wait_time = 0.5
    timer_fps.one_shot = false
    timer_fps.autostart = false
    timer_fps.timeout.connect(_on_timer_fps_timeout)
    add_child(timer_fps)

    Editor.main.creative_mode_view.combo_rating_changed.connect(text_edit._on_combo_rating_vis_changed)
    Editor.main.creative_mode_view.combo_rating_changed.connect(text_edit_secondary._on_combo_rating_vis_changed)

func connect_signals() -> void:
    text_edit.focus_entered.connect(_on_editor_focus_entered.bind(text_edit))
    text_edit_secondary.focus_entered.connect(_on_editor_focus_entered.bind(text_edit_secondary))
    TinyIME.ime_state_changed.connect(_on_ime_state_changed)

func _on_key_sequence_matched(binding: KeySystem.KeyBinding) -> void:
    print("Debug - Key matched:", binding.sequence[0], binding.command)
    last_focused_editor.show_char(binding.sequence[0])
    match binding.command:
        "new_file":   new_document()
        "open_file":  open_document()
        "save_file":  save_document()
        "toggle_setting": toggle_setting()
        "toggle_effect":  toggle_effect()
        "toggle_ime":     TinyIME.toggle()
        "toggle_ime_fullwidth_punc":     TinyIME.toggle_fullwidth()
        "toggle_locale":  toggle_locale()
        "start_motion":   show_command_window()
        "start_command": show_execution_window()

func _on_editor_focus_entered(editor: TextEdit) -> void:
    last_focused_editor = editor
func _on_ime_state_changed(v):
    if v:
        lb_ime.text  = 'CN'
    else:
        lb_ime.text  = 'EN'

func show_command_window() -> void:
    if Editor.main.mask.visible: return
    if current_motion_window != null and is_instance_valid(current_motion_window):
        return
    
    # last_focused_editor = text_edit if text_edit.has_focus() else text_edit_secondary if text_edit_secondary.has_focus() else null
    
    current_motion_window = preload("res://scenes/motion_window.tscn").instantiate()
    current_motion_window.set_available_commands(motions.available_commands)
    main.add_child(current_motion_window)
    
    await get_tree().process_frame
    
    var window_size = Vector2(400, 200)
    var viewport_size = get_viewport_rect().size
    current_motion_window.position = Vector2i((viewport_size - window_size) / 2)
    
    current_motion_window.command_executed.connect(_on_command_executed)
    current_motion_window.command_canceled.connect(_on_command_canceled)
    
    pre_sub_window_show(current_motion_window, current_motion_window._on_close_requested)

func _on_command_executed(command: String) -> void:
    motions.execute_command(command)
    # self.log('mot: %s' % [command])
    current_motion_window = null

    post_sub_window_hide()

func _on_command_canceled():
    current_motion_window = null
    post_sub_window_hide()

# 执行窗口相关函数
func show_execution_window() -> void:
    if Editor.main.mask.visible: return
    if current_execution_window != null and is_instance_valid(current_execution_window):
        return
    
    # last_focused_editor = text_edit if text_edit.has_focus() else text_edit_secondary if text_edit_secondary.has_focus() else null
    
    current_execution_window = preload("res://scenes/execution_window.tscn").instantiate()
    main.add_child(current_execution_window)
    current_execution_window.set_available_executors(executions.available_executors)
    
    await get_tree().process_frame
    
    var window_size = Vector2(400, 200)
    var viewport_size = get_viewport_rect().size
    current_execution_window.position = Vector2i((viewport_size - window_size) / 2)
    
    current_execution_window.execution_requested.connect(_on_execution_requested)
    current_execution_window.execution_canceled.connect(_on_execution_canceled)
    
    pre_sub_window_show(current_execution_window, current_execution_window._on_close_requested)

func _on_execution_requested(command: String, args: Dictionary):
    # self.log('cmd: %s, args: %s' % [command, args])
    executions.execute_command(command, args)
    _on_execution_canceled()

func _on_execution_canceled():
    current_execution_window = null
    post_sub_window_hide()

# ---------------------------
func pre_sub_window_show(win=null, cancel_func=null, is_click=false):
    if win: Editor.mask.set_window(win, cancel_func, is_click)

    main.mask.show()

    if last_focused_editor:
        last_focused_editor.release_focus()
        last_focused_editor.get_window().set_ime_active(false)

    text_edit.editable = false
    text_edit.is_active = false
    text_edit_secondary.editable = false
    text_edit_secondary.is_active = false

func post_sub_window_hide():
    Editor.mask.hide()
    Editor.mask.clear_window()
    text_edit.editable = true
    text_edit_secondary.editable = true
    await get_tree().process_frame
    if last_focused_editor:
        last_focused_editor.get_window().set_ime_active(true)
        last_focused_editor.grab_focus()
        last_focused_editor.is_active = true

# ---------------------------
func open_document():
    core.document_manager.show_file_dialog()
    pre_sub_window_show()
    var file_path = await core.document_manager.file_selected
    post_sub_window_hide()
    if file_path:
        open_document_from_path(file_path)

func save_document():
    var file_path = ''
    if get_current_file_path() == '':
        var dlg = core.document_manager.show_save_dialog()
        pre_sub_window_show()
        file_path = await core.document_manager.file_selected
        post_sub_window_hide()
        if file_path:
            core.config_manager.set_basic_setting("recent_file", file_path)
        else:
            return
    var document = get_current_document()
    var content = last_focused_editor.text
    if core.document_manager.save_document(document, content, file_path):
        set_document_saved()
        toast('%s\n%s' % [tr('FILE_SAVED'), DocumentManager.get_home_folded(document.file_path)])
        show_hint('%s:%s' % [tr('FILE_SAVED') , DocumentManager.get_home_folded(document.file_path)])
        _update_title()
        _update_count()
    else:
        toast('%s\n%s' % [tr('FILE_SAVE_ERROR'), DocumentManager.get_home_folded(document.file_path)])

func new_document():
    if is_document_dirty():
        UI.show_dialog('NOT_SAVED', 'CONTINUE_CREATE_NEW_FILE', _new_document)
    else:
        _new_document()
func _new_document():
    var doc = core.document_manager.new_document()
    last_focused_editor.document = doc
    _update_title()
    _update_count()
    toast('%s' % [tr('FILE_NEW')])
    show_hint('%s' % [tr('FILE_NEW')])
    core.config_manager.set_basic_setting("recent_file", '')

func open_document_from_path(file_path: String) -> void:
    var doc = core.document_manager.open_document(file_path)
    if doc:
        last_focused_editor.document = doc
        last_focused_editor.move_caret_to_file_end()
        core.config_manager.set_basic_setting("recent_file", file_path)
        toast('%s\n%s' % [tr('FILE_OPENED'), DocumentManager.get_home_folded(file_path)])
        show_hint('%s:%s' % [tr('FILE_OPENED') , DocumentManager.get_home_folded(file_path)])
        _update_title()
        _update_count()
    else:
        toast('%s\n%s' % [tr('FILE_OPEN_ERROR'), DocumentManager.get_home_folded(file_path)])

func _update_title():
    var d = '* ' if is_document_dirty() else ''
    var f_p = get_current_file_path()
    var f = f_p.get_file() if f_p else 'Untitled'
    set_title(d+f)

func _update_count():
    lb_count.text = '%dC' % last_focused_editor.text.length() 

func get_current_base_dir():
    return last_focused_editor.document.file_path.get_base_dir()
func get_current_file_name():
    return last_focused_editor.document.file_path.get_file()
func get_current_file_path():
    return last_focused_editor.document.file_path
func is_document_dirty():
    return last_focused_editor.is_dirty
func is_document_empty():
    return last_focused_editor.text.is_empty() 
func set_document_saved():
    last_focused_editor.is_dirty = false
func get_current_document():
    return last_focused_editor.document

func update_status_bar(edit):
    if last_focused_editor == edit:
        _update_count()
        _update_title()
        show_hint('')

# ---------------------------
func toast(txt):
    var ts = Toast.instantiate()
    ts.font_res = _font_res_ui
    add_child(ts)
    ts.text = txt
    UI.set_layout(ts, UI.PRESET_CENTER_TOP, Vector2(0, 60))
    ts.pivot_offset = ts.size / 2.0
    ts.modulate.a = 0.0
    ts.scale = Vector2(3, 3)
    TwnLite.at(ts).tween({
        prop='modulate:a',
        from=0.0,
        to=1.0,
        dur=0.3,
    }).tween({
        prop='scale',
        from=Vector2(4, 4),
        to=Vector2(1, 1),
        dur=0.3,
        parallel=true,
        ease=Tween.EASE_OUT,
        trans=Tween.TRANS_EXPO,
    }).delay(3.0).tween({
        prop='position:y',
        from=60,
        to=30,
        dur=0.3,
    }).tween({
        prop='modulate:a',
        from=1.0,
        to=0.0,
        dur=0.3,
        parallel=true,
    }).delay(0.3).callee(ts.queue_free)

func show_hint(txt):
    status.text = txt
    # await get_tree().create_timer(4.0).timeout
    # status.text = ''

func set_title(file_path):
    DisplayServer.window_set_title(file_path)

func _on_autosave_timeout():
    if get_current_file_path() != '' and is_document_dirty():
        var document = get_current_document()
        var content = last_focused_editor.text
        if core.document_manager.save_document(document, content):
            set_document_saved()
            show_hint('%s:%s' % [tr('FILE_AUTO_SAVED') , DocumentManager.get_home_folded(document.file_path)])
            _update_title()
# ---------------------------
func toggle_locale():
    var locale = TranslationServer.get_locale()
    if locale != 'zh':
        TranslationServer.set_locale("zh")
    else:
        TranslationServer.set_locale("en")

    _update_placeholder()

func toggle_setting():
    # UI.toggle_node_from_raw('ui/settings:Settings', {parent=Editor.main.canvas})
    var nd = UI.toggle_node_from_raw('ui/settings:Settings', {parent=Editor.main.canvas})
    Editor.main.mask.visible = nd.visible
    if nd.visible:
        pre_sub_window_show()
        Editor.config.random_tip()
        # Editor.mask.set_window(nd, hide_setting_panel, true)
    else:
        post_sub_window_hide()
        # Editor.mask.clear_window()
        
# func hide_setting_panel():
    # var nd = UI.get_node_or_null_from_raw('ui/settings:Settings', {parent=Editor.main.canvas})
    # if nd:
        # nd.hide()
        # post_sub_window_hide()


func toggle_effect():
    var efx = Editor.config.get_setting('effect', 'fx_switch')
    efx = 0 if efx else 1
    Editor.config.set_setting('effect', 'fx_switch', efx)

func set_debug(v):
    if v:
        stat_box.show()
        log_box.show()
        timer_fps.start()
        _on_timer_fps_timeout()
    else:
        stat_box.hide()
        log_box.hide()
        timer_fps.stop()

    for te in [text_edit, text_edit_secondary]:
        te.is_debug = v

func _on_timer_fps_timeout():
    # Get performance info
    var fps = Performance.get_monitor(Performance.TIME_FPS)
    var os_name = OS.get_distribution_name()
    var draw_call = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    var vram_usage = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1024.0 / 1024.0  # Convert to MB
    
    # Format the stats
    stat_box.get_node('OS').text = "OS: %s" % os_name
    stat_box.get_node('FPS').text = "FPS: %.1f" % fps
    stat_box.get_node('DRAW').text = "DRAW CALL: %.1f" % draw_call
    stat_box.get_node('VRAM').text = "VRAM: %.1f MB" % vram_usage

func log(txt: String) -> void:
    # Create new log label
    var log_label = Label.new()
    log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    log_label.text = "%s [%s]" % [txt, Time.get_time_string_from_system()]
    log_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
    
    # Add to log box
    log_box.add_child(log_label)

    # Remove oldest log if exceeding 15 entries
    var will_remove = []
    if log_box.get_child_count() > 15:
        for i in log_box.get_child_count() - 15:
            var log_c = log_box.get_child(i)
            will_remove.append(log_c)

    for c in will_remove:
        log_box.remove_child(c)
        c.queue_free()
# =========================================
func subscribe_configs():
    _init_language()
    Editor.config.subscribe('basic', 'language', self, _set_language, false)
    Editor.config.subscribe('basic', 'auto_save', self, _set_auto_save, true)
    Editor.config.subscribe('basic', 'show_char_count', self, _set_char_count, true)
    Editor.config.subscribe('basic', 'highlight_line', self, _set_highlight_line, true)

    Editor.config.subscribe('basic', 'line_number', self, _set_line_number, true)

    Editor.config.subscribe('basic', 'line_wrap', self, _set_line_wrap, true)

    Editor.config.subscribe('interface', 'font_size', self, _update_font_size, true)

    Editor.config.subscribe('interface', 'editor_font', self, _set_font.bind('editor'), true)
    Editor.config.subscribe('interface', 'effect_font', self, _set_font.bind('effect'), true)
    Editor.config.subscribe('interface', 'interface_font', self, _set_font.bind('interface'), true)
    Editor.config.subscribe('interface', 'pad_lines', self, _set_pad_lines, true)
    Editor.config.init_only('basic', 'auto_open_recent', self, _set_auto_open_recent)

    for key in Editor.config.get_keys('effect'):
        Editor.config.subscribe('effect', key, self, _set_effect.bind(key), true)

    setup_key_bindings()

    for key in Editor.config.get_keys('shortcut'):
        if key == 'mac_prefix_use_option':
            Editor.config.subscribe('shortcut', key, self, _set_prefix_ctrl, true)
        else:
            Editor.config.subscribe('shortcut', key, self, _set_binding.bind(key), true)
        # setup_key_bindings(key)

    Editor.config.subscribe('ime', 'pinyin_icon', self, _set_ime_icon, true)
    # Editor.config.subscribe('ime', 'shuangpin', self, TinyIME.set_shuangpin, true)
    Editor.config.subscribe('ime', 'pinyin_page_size', self, _set_ime_page_size, true)
    Editor.config.subscribe('ime', 'prev_page_key', self, _set_ime_key.bind('prev_page_key'), true)
    Editor.config.subscribe('ime', 'next_page_key', self, _set_ime_key.bind('next_page_key'), true)
    Editor.config.subscribe('ime', 'pinyin_fullwidth', self, _set_ime_fullwidth, true)

var lang = 'zh'
func _init_language():
    var os_lang = OS.get_locale_language()
    if os_lang in ['zh', 'en']:
        lang = os_lang
    else:
        lang = 'en'
    var is_set = Editor.config.get_setting('basic', 'is_language_set')
    if is_set: 
        var idx = Editor.config.get_setting('basic', 'language')
        lang = Editor.config.SETTINGS_CONFIG.basic.language.values[idx]
    else:
        if lang == 'en':
            #NOTE SHOULD ALSO SET THE LANGUAGE Option Node?
            Editor.config.opt_lang.select(1)
    TranslationServer.set_locale(lang)
    _update_placeholder()

func _set_language(lang_idx):
    # XXX: this key should after language, as it will override in reset all
    Editor.config.set_setting_no_signal('basic', 'is_language_set', 1)
    lang = Editor.config.SETTINGS_CONFIG.basic.language.values[lang_idx]
    TranslationServer.set_locale(lang)
    _update_placeholder()

func _set_auto_save(v):
    if v and autosave_timer.is_stopped():
        autosave_timer.start(AUTOSAVE_INTERVAL)
    elif not v:
        autosave_timer.stop()
func _set_auto_open_recent(v):
    if v:
        var recent_file = core.config_manager.get_basic_setting("recent_file")
        if recent_file: open_document_from_path(recent_file)
func _set_char_count(v: bool):
    lb_count.visible = v
func _set_line_wrap(v):
    for te in [text_edit, text_edit_secondary]:
        if v:
            te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
            te.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
        else:
            te.wrap_mode = TextEdit.LINE_WRAPPING_NONE
            te.autowrap_mode = TextServer.AUTOWRAP_OFF

func _set_line_number(v):
    for te in [text_edit, text_edit_secondary]:
        te.update_gutter()
func _set_highlight_line(v):
    for te in [text_edit, text_edit_secondary]:
        te.highlight_current_line = v

var _font_size
var _font_size_real
func _update_font_size(f):
    var v = Editor.config.SETTINGS_CONFIG.interface.font_size.values[f]
    _font_size = f
    _font_size_real = v
    for te in [text_edit, text_edit_secondary]:
        te.set("theme_override_font_sizes/font_size", v)
        te.font_size = f
        # te.update_gutter()
    await get_tree().process_frame
    redraw()

var _font_res_ui
var _font_res_fx
var _font_res = preload('res://effects/font.tres')
func _set_font(idx, type):
    if type == 'editor':
        var font = Editor.config.SETTINGS_CONFIG.interface.editor_font.values[idx]
        for te in [text_edit, text_edit_secondary]:
            te.set("theme_override_fonts/font", load("res://assets/fonts/" + font))
        redraw()
    elif type == 'effect':
        var is_init = false
        if _font_res_fx == null:
            _font_res_fx = _font_res.duplicate(true)
            is_init = true
        var font = Editor.config.SETTINGS_CONFIG.interface.effect_font.values[idx]
        _font_res_fx.base_font = load('res://assets/fonts/' + font)
        for te in [text_edit, text_edit_secondary]:
            te.font_res_fx = _font_res_fx
        if is_init:
            Editor.main.creative_mode_view.font_res_fx = _font_res_fx
    elif type == 'interface':
        var is_init = false
        if _font_res_ui== null:
            _font_res_ui = _font_res.duplicate(true)
            is_init = true
        var font = Editor.config.SETTINGS_CONFIG.interface.effect_font.values[idx]
        _font_res_ui.base_font = load('res://assets/fonts/' + font)

        for te in [text_edit, text_edit_secondary]:
            te.font_res_ui = _font_res_ui

        if is_init:
            Editor.main.creative_mode_view.font_res_ui = _font_res_ui

func get_font_fx():
    return _font_res_fx
func get_font_ui():
    return _font_res_ui
func get_font_size():
    return _font_size
func get_font_size_real():
    return _font_size_real
func _set_pad_lines(v):
    for te in [text_edit, text_edit_secondary]:
        te.pad_lines = v
# -----------------
func _set_effect(v, type):
    var fxs = {}
    var fx_switch = Editor.config.get_effect_setting('fx_switch')
    if type == 'fx_switch':
        fxs = {
            "audio":      0 if !fx_switch else Editor.config.get_effect_setting("audio"),
            "combo":      0 if !fx_switch else Editor.config.get_effect_setting("combo"),
            "combo_shot": 0 if !fx_switch else Editor.config.get_effect_setting("combo_shot"),
            "shake":      0 if !fx_switch else Editor.config.get_effect_setting("screen_shake_level"),
            "chars":      0 if !fx_switch else Editor.config.get_effect_setting("char_effect"),
            "particles":  0 if !fx_switch else Editor.config.get_effect_setting("char_particle"),
            "newline":    0 if !fx_switch else Editor.config.get_effect_setting("newline_effect"),
            "delete":     0 if !fx_switch else Editor.config.get_effect_setting("delete_effect"),
            "match_effect":      0 if !fx_switch else Editor.config.get_effect_setting("match_effect"),
            "sound_increase":      0 if !fx_switch else Editor.config.get_effect_setting("char_sound_increase"),
        }
        for te in [text_edit, text_edit_secondary]:
            for k in fxs:
                te.effects[k] = fxs[k]
    else:
        var fx_key = type
        match type:
            'screen_shake_level': fx_key = 'shake'
            'char_effect':        fx_key = 'chars'
            'char_particle':      fx_key = 'particles'
            'newline_effect':       fx_key = 'newline'
            'delete_effect':      fx_key = 'delete'
            'char_sound_increase': fx_key = 'sound_increase'
        for te in [text_edit, text_edit_secondary]:
            if type == 'match_words':
                te.effects[fx_key] = Array(v.replace('，',',').split(','))
            elif type == 'char_sound':
                te.effects['sound'] = Editor.config.SETTINGS_CONFIG.effect.char_sound.values[v]
            else:
                te.effects[fx_key] = 0 if !fx_switch else v
# -----------------
func _set_ime_icon(v):
    lb_ime.visible = v

func _set_ime_page_size(v):
    TinyIME.set_page_size(v)

func _set_ime_key(v, k):
    TinyIME.set_key(k, v)

func _set_ime_fullwidth(v):
    TinyIME.set_fullwidth(v)

# -----------------
func redraw():
    var orig_set = Editor.config.get_setting('basic', 'line_wrap')
    var wrap_from
    var wrap_to
    if orig_set:
        wrap_from = TextServer.AUTOWRAP_OFF
        wrap_to = TextServer.AUTOWRAP_ARBITRARY
    else:
        wrap_from = TextServer.AUTOWRAP_ARBITRARY
        wrap_to = TextServer.AUTOWRAP_OFF

    for edit in [text_edit, text_edit_secondary]:
        edit.autowrap_mode = wrap_from
    await get_tree().process_frame
    for edit in [text_edit, text_edit_secondary]:
        edit.autowrap_mode = wrap_to
    # await get_tree().process_frame
    # for edit in [text_edit, text_edit_secondary]:
    #     edit.pad_viewport_to_caret()
    # await get_tree().process_frame
    # for edit in [text_edit, text_edit_secondary]:
    #     edit._on_caret_changed()
# ---------------
func _set_prefix_ctrl(v):
    for edit in [text_edit, text_edit_secondary]:
        edit.mac_prefix_use_option = v

func _set_binding(val, key):
    core.key_system.set_binding(
        [val],
        key,
        "editorFocus"
    )
    if key in ['new_file', 'open_file', 'save_file', 'toggle_setting', 'toggle_ime', 'start_motion', 'start_command']:
        _update_placeholder()
func _update_placeholder():
        text_edit.placeholder_text = tr('PLACEHOLDER_TIP').format({
                new_file       = _get_shortcut_shown('new_file'),
                open_file      = _get_shortcut_shown('open_file'),
                save_file      = _get_shortcut_shown('save_file'),
                toggle_setting = _get_shortcut_shown('toggle_setting'),
                toggle_ime     = _get_shortcut_shown('toggle_ime'),
                start_motion   = _get_shortcut_shown('start_motion'),
                start_command  = _get_shortcut_shown('start_command'),
            })

func _get_shortcut_shown(key):
    return Editor.config.get_key_shown(Editor.config.get_setting('shortcut', key))

func setup_key_bindings() -> void:

    # if Engine.is_editor_hint():
    if OS.has_feature("editor"):
        core.key_system.set_binding(
            ["Ctrl+1"],
            "toggle_locale",
            "editorFocus"
        )
        print('set locale')

    core.key_system.sequence_matched.connect(_on_key_sequence_matched)

    # 添加命令窗口快捷键
    
    # # 添加执行窗口快捷键
    # core.key_system.set_binding(
    #     ["Ctrl+R"],
    #     "show_execution",
    #     "editorFocus"
    # )

    # core.key_system.set_binding(
    #     ["Ctrl+Apostrophe"],
    #     "toggle_setting",
    #     "editorFocus"
    # )

    # # NOTE: if is macos, use Option, else use Alt
    # core.key_system.set_binding(
    #     ["Option+Escape"],
    #     "toggle_ime",
    #     "editorFocus"
    # )

    # var key_save = ''
    # # NOTE: if is macos, use Command, else use Ctrl
    # if Editor.is_macos:
    #     key_save = "Command+O"
    # else:
    #     key_save = "Ctrl+O"
    # core.key_system.set_binding(
    #     # [key_save],
    #     ["Ctrl+O"],
    #     "open_document",
    #     "editorFocus"
    # )

    # core.key_system.set_binding(
    #     ["Ctrl+S"],
    #     "save_document",
    #     "editorFocus"
    # )

    # core.key_system.set_binding(
    #     ["Ctrl+N"],
    #     "new_document",
    #     "editorFocus"
    # )
func _on_files_dropped(files: PackedStringArray) -> void:
    for file_path in files:
        # Check if the file is an txt
        if file_path.get_extension().to_lower() in ["txt", "md", "rst", "py", "json", "text", "ini", "js", "gd"]:
            open_document_from_path(file_path)
            return

    toast('OPEN_EXT_FILE_FAILED')


func _preload_effects():
    var thing
    thing = WildEdit.Blip.instantiate()
    thing.audio = false
    thing.blips = true
    thing.last_key = ''
    add_child(thing)
    thing.hide()
    thing = WildEdit.Boom.instantiate()
    thing.audio = false
    thing.blips = true
    thing.hide()
    add_child(thing)
    thing = WildEdit.Laser.instantiate()
    thing.audio = false
    thing.hide()
    add_child(thing)
    thing = WildEdit.BoomBig.instantiate()
    thing.audio = false
    thing.blips = true
    thing.last_key = ''
    thing.animation = '2'
    thing.hide()
    add_child.call_deferred(thing)
    thing = WildEdit.Dust.instantiate()
    thing.audio = false
    thing.blips = true
    thing.hide()
    add_child.call_deferred(thing)
    thing = WildEdit.Newline.instantiate()
    thing.hide()
    add_child.call_deferred(thing)
