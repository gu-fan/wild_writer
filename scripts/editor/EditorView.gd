class_name EditorView
extends Control

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
@onready var debug: Button = $VBoxContainer/Panel/HBoxContainer/Debug
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
    setup_key_bindings()

    Editor.config = core.config_manager

    # 加载配置
    core.config_manager.load_config()
    core.config_manager.build_ui()

    
    last_focused_editor = text_edit
    last_focused_editor.document = core.document_manager.new_document()

    
    # # 检查是否需要自动打开最近的文件
    # if core.config_manager.get_basic_setting("auto_open_recent"):
    #     var recent_file = core.config_manager.get_basic_setting("recent_file")
    #     if recent_file and FileAccess.file_exists(recent_file):
    #         open_document_from_path(recent_file)
            
    #         # 恢复光标位置
    #         var caret_line = core.config_manager.get_basic_setting("backup_caret_line")
    #         var caret_col = core.config_manager.get_basic_setting("backup_caret_col")
    #         if last_focused_editor:
    #             last_focused_editor.set_caret_line(caret_line)
    #             last_focused_editor.set_caret_column(caret_col)
    #             last_focused_editor.center_viewport_to_caret()


    subscribe_configs()

    await get_tree().create_timer(0.1).timeout
    last_focused_editor.call_deferred('grab_focus')

    autosave_timer.timeout.connect(_on_autosave_timeout)
    
func setup_view() -> void:
    # 设置编辑器基本属性
    text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY if core.config_manager.get_basic_setting("line_wrap") else TextEdit.LINE_WRAPPING_NONE
    # text_edit.gutters_draw_line_numbers = core.config_manager.get_basic_setting("line_number")
    text_edit.highlight_current_line = core.config_manager.get_basic_setting("highlight_line")
    
    text_edit_secondary.wrap_mode = text_edit.wrap_mode
    text_edit_secondary.gutters_draw_line_numbers = text_edit.gutters_draw_line_numbers
    text_edit_secondary.highlight_current_line = text_edit.highlight_current_line
    text_edit.changed.connect(update_status_bar.bind(text_edit))
    text_edit_secondary.changed.connect(update_status_bar.bind(text_edit_secondary))

    
    # 初始隐藏第二编辑器
    secondary_container.hide()

    locale.pressed.connect(toggle_locale)
    setting.pressed.connect(toggle_setting)
    debug.pressed.connect(toggle_debug)
    timer_fps = Timer.new()
    timer_fps.wait_time = 0.5
    timer_fps.one_shot = false
    timer_fps.autostart = false
    timer_fps.timeout.connect(_on_timer_fps_timeout)
    add_child(timer_fps)

    # var count = text_edit.get_gutter_count()
    # for i in count:
    #     var gut_name = text_edit.get_gutter_name(i)
    #     if gut_name == 'line_numbers':
    #         var gutter_size = 20
    #         var gutter_size_fin = max(4*gutter_size, (3+1)*gutter_size)
    #         text_edit.set_gutter_width(i, gutter_size_fin)

    Editor.main.creative_mode_view.combo_rating_changed.connect(text_edit._on_combo_rating_vis_changed)
    Editor.main.creative_mode_view.combo_rating_changed.connect(text_edit_secondary._on_combo_rating_vis_changed)

func connect_signals() -> void:
    text_edit.focus_entered.connect(_on_editor_focus_entered.bind(text_edit))
    text_edit_secondary.focus_entered.connect(_on_editor_focus_entered.bind(text_edit_secondary))
    TinyIME.ime_state_changed.connect(_on_ime_state_changed)

func setup_key_bindings() -> void:
    # 添加命令窗口快捷键
    core.key_system.add_binding(
        ["Ctrl+E"],
        "show_command",
        "editorFocus"
    )

    
    # 添加执行窗口快捷键
    core.key_system.add_binding(
        ["Ctrl+R"],
        "show_execution",
        "editorFocus"
    )

    core.key_system.add_binding(
        ["Ctrl+1"],
        "toggle_locale",
        "editorFocus"
    )

    core.key_system.add_binding(
        ["Ctrl+Apostrophe"],
        "toggle_setting",
        "editorFocus"
    )

    # NOTE: if is macos, use Option, else use Alt
    core.key_system.add_binding(
        ["Option+Escape"],
        "toggle_ime",
        "editorFocus"
    )

    var key_save = ''
    # NOTE: if is macos, use Command, else use Ctrl
    if Editor.is_macos:
        key_save = "Command+O"
    else:
        key_save = "Ctrl+O"
    core.key_system.add_binding(
        # [key_save],
        ["Ctrl+O"],
        "open_document",
        "editorFocus"
    )

    core.key_system.add_binding(
        ["Ctrl+S"],
        "save_document",
        "editorFocus"
    )

    core.key_system.add_binding(
        ["Ctrl+N"],
        "new_document",
        "editorFocus"
    )

    core.key_system.sequence_matched.connect(_on_key_sequence_matched)

func _on_key_sequence_matched(binding: KeySystem.KeyBinding) -> void:
    print("Debug - Key sequence matched:", binding.command)
    match binding.command:
        "show_command":   show_command_window()
        "show_execution": show_execution_window()
        "toggle_ime":     TinyIME.toggle()
        "toggle_setting": toggle_setting()
        "toggle_locale":  toggle_locale()
        "open_document":  open_document()
        "save_document":  save_document()
        "new_document":   new_document()

func _on_editor_focus_entered(editor: TextEdit) -> void:
    last_focused_editor = editor
func _on_ime_state_changed(v):
    if v:
        lb_ime.text  = 'CN'
    else:
        lb_ime.text  = 'EN'

func show_command_window() -> void:
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
    
    pre_sub_window_show()


func _on_command_executed(command: String) -> void:
    motions.execute_command(command)
    logging('mot: %s' % [command])
    
    current_motion_window = null

    post_sub_window_hide()

func _on_command_canceled():
    current_motion_window = null
    post_sub_window_hide()

# 执行窗口相关函数
func show_execution_window() -> void:
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
    
    pre_sub_window_show()

func _on_execution_requested(command: String, args: Dictionary):
    logging('cmd: %s, args: %s' % [command, args])
    executions.execute_command(command, args)
    _on_execution_canceled()

func _on_execution_canceled():
    current_execution_window = null
    post_sub_window_hide()
# ---------------------------
func pre_sub_window_show():
    main.mask.show()

    if last_focused_editor:
        last_focused_editor.release_focus()
        last_focused_editor.get_window().set_ime_active(false)

    text_edit.editable = false
    text_edit.is_active = false
    text_edit_secondary.editable = false
    text_edit_secondary.is_active = false

func post_sub_window_hide():
    main.mask.hide()
    text_edit.editable = true
    text_edit_secondary.editable = true
    await get_tree().process_frame
    if last_focused_editor:
        last_focused_editor.get_window().set_ime_active(true)
        last_focused_editor.grab_focus()
        last_focused_editor.is_active = true

# ---------------------------
# CHECKLIST - documents
# new
# open
# save
# open_recent
# auto_save
# document_dir
func open_document():
    core.document_manager.show_file_dialog()
    var file_path = await core.document_manager.file_selected
    if file_path:
        open_document_from_path(file_path)

func save_document():
    var file_path = ''
    if get_current_file_path() == '':
        core.document_manager.show_save_dialog()
        file_path = await core.document_manager.file_selected
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
var current_file_path: String = ""

# 文件操作相关函数
func open_document_from_path2(path: String) -> void:
    if not FileAccess.file_exists(path):
        push_warning("File not found: %s" % path)
        return
    
    var file = FileAccess.open(path, FileAccess.READ)
    if file:
        var content = file.get_as_text()
        file.close()
        
        # 更新编辑器内容
        if last_focused_editor:
            last_focused_editor.text = content
            last_focused_editor.clear_undo_history()
        
        # 更新当前文件路径
        current_file_path = path
        
        # 更新最近文件记录
        core.config_manager.set_basic_setting("recent_file", path)
        
        # 更新状态栏
        status.text = "Opened: " + path

func save_document2() -> void:
    if not last_focused_editor:
        return
        
    if current_file_path.is_empty():
        save_document_as()
        return
    
    # 保存文件
    var content = last_focused_editor.text
    var file = FileAccess.open(current_file_path, FileAccess.WRITE)
    if file:
        file.store_string(content)
        file.close()
        
        # 更新最近文件记录和光标位置
        core.config_manager.set_basic_setting("recent_file", current_file_path)
        core.config_manager.set_basic_setting("backup_caret_line", last_focused_editor.get_caret_line())
        core.config_manager.set_basic_setting("backup_caret_col", last_focused_editor.get_caret_column())
        
        # 更新状态栏
        status.text = "Saved: " + current_file_path

func save_document_as() -> void:
    # 如果已有对话框打开，就返回
    if current_file_dialog != null and is_instance_valid(current_file_dialog):
        return
        
    current_file_dialog = FileDialog.new()
    current_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    current_file_dialog.add_filter("*.txt;*.md;*.json", "Text files")
    current_file_dialog.add_filter("*", "All files")
    
    # 设置对话框大小和标题
    current_file_dialog.title = "Save File As"
    current_file_dialog.size = Vector2(800, 600)
    
    add_child(current_file_dialog)
    current_file_dialog.popup_centered()
    
    # 等待文件选择
    var file_path = await current_file_dialog.file_selected
    current_file_dialog.queue_free()
    current_file_dialog = null  # 清除引用
    
    if file_path:
        current_file_path = file_path
        save_document()

# ---------------------------
func toggle_locale():
    var locale = TranslationServer.get_locale()
    if locale != 'zh':
        TranslationServer.set_locale("zh")
    else:
        TranslationServer.set_locale("en")

func toggle_setting():
    # UI.toggle_node_from_raw('ui/settings:Settings', {parent=Editor.main.canvas})
    var nd = UI.toggle_node_from_raw('ui/settings:Settings', {parent=Editor.main.canvas})
    Editor.main.mask.visible = nd.visible
    if nd.visible:
        pre_sub_window_show()
    else:
        post_sub_window_hide()

func toggle_debug():
    if stat_box.visible:
        stat_box.hide()
        log_box.hide()
        timer_fps.stop()
    else:
        stat_box.show()
        log_box.show()
        timer_fps.start()
        _on_timer_fps_timeout()

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

func logging(txt: String) -> void:
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
    Editor.config.subscribe('basic', 'font_size', self, _update_font_size, true)
    Editor.config.subscribe('basic', 'auto_save', self, _set_auto_save, true)
    Editor.config.init_only('basic', 'auto_open_recent', self, _set_auto_open_recent)
    Editor.config.subscribe('basic', 'show_char_count', self, _set_char_count, true)
    Editor.config.subscribe('basic', 'line_wrap', self, _set_line_wrap, true)
    Editor.config.subscribe('basic', 'line_number', self, _set_line_number, true)
    Editor.config.subscribe('basic', 'highlight_line', self, _set_highlight_line, true)

func _update_font_size(f):
    for te in [text_edit, text_edit_secondary]:
        match f:
            0: te.set("theme_override_font_sizes/font_size", 16)
            1: te.set("theme_override_font_sizes/font_size", 32)
            2: te.set("theme_override_font_sizes/font_size", 48)
            3: te.set("theme_override_font_sizes/font_size", 96)

func _set_auto_save(v):
    if v and autosave_timer.is_stopped():
        autosave_timer.start(AUTOSAVE_INTERVAL)
    elif not v:
        autosave_timer.stop()
func _set_auto_open_recent(v):
    if v:
        var recent_file = core.config_manager.get_basic_setting("recent_file")
        open_document_from_path(recent_file)
func _set_char_count(v: bool):
    lb_count.visible = v
func _set_line_wrap(v):
    if v:
        last_focused_editor.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
    else:
        last_focused_editor.autowrap_mode = TextServer.AUTOWRAP_OFF
func _set_line_number(v):
    last_focused_editor.update_gutter()
func _set_highlight_line(v):
    last_focused_editor.highlight_current_line = v
# =========================================
