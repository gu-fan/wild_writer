extends Node2D

var file_manager: FileManager

@onready var ime = TinyIME

@onready var bottom_label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/BottomPanel/HBoxContainer/Label
@onready var char_label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/BottomPanel/HBoxContainer/Char
@onready var ime_button: Button = $CanvasLayer/Control/MarginContainer/VBoxContainer/BottomPanel/HBoxContainer/IMEButton
@onready var setting_button: Button = $CanvasLayer/Control/MarginContainer/VBoxContainer/BottomPanel/HBoxContainer/SettingButton
@onready var editor_man: TinyEditor = $CanvasLayer
@onready var settings: Control = $CanvasLayer/Settings

var editor

var is_dirty = false : set = _set_is_dirty
var current_file_path = ''

const AUTOSAVE_INTERVAL = 60.0  # 自动保存间隔（秒）
const BACKUP_INTERVAL = 5.0     # 备份间隔（秒）
var autosave_timer: Timer
var backup_timer: Timer

# 添加常量定义快捷键动作名称
const ACTIONS = {
    "new_file": "new",
    "open_file": "open",
    "save_file": "save",
    "open_setting": "setting"
}

func _ready():
    file_manager = FileManager.new()
    add_child(file_manager)

    editor = editor_man.editor

    editor_man.bottom_label = bottom_label
    editor_man.ime_button = ime_button
    editor_man.setting_button = setting_button
    editor_man.init()

    editor_man.typing.connect(_on_typing)

    setting_button.pressed.connect(_toggle_setting)

    # 初始化定时器
    autosave_timer = Timer.new()
    backup_timer = Timer.new()
    add_child(autosave_timer)
    add_child(backup_timer)
    
    autosave_timer.timeout.connect(_on_autosave_timeout)
    backup_timer.timeout.connect(_on_backup_timeout)

    load_settings(true)

    backup_timer.start(BACKUP_INTERVAL)
    
    # 监听设置变化
    SettingManager.setting_changed.connect(_on_setting_changed)
    DisplayServer.window_set_drop_files_callback(_on_files_dropped)

    # show caret
    editor_man.editor.grab_focus()


func load_settings(is_init=false):
    if is_init:
        _load_auto_open_file()
        _init_gutter()
        editor_man.update_editor_stats()
        _update_about_and_logs()

    _on_setting_changed()

func _init_gutter():
    editor_man._init_gutter()

func _update_editor_effects():
    # Retrieve effect settings from SettingManager
    var effect_level = SettingManager.get_effect_setting("level")
    
    # Update editor_man effects dictionary
    editor_man.effects = {
        "level": effect_level,
        "shake": effect_level and SettingManager.get_effect_setting("screen_shake"),
        "chars": effect_level and SettingManager.get_effect_setting("char_effect"),
        "particles": effect_level and SettingManager.get_effect_setting("char_particle"),
        "newline": effect_level and SettingManager.get_effect_setting("enter_effect"),
        "combo": effect_level and SettingManager.get_effect_setting("combo"),
        "combo_shot": effect_level and SettingManager.get_effect_setting("combo_shot"),
        "audio": effect_level and SettingManager.get_effect_setting("audio"),
        "delete": effect_level and SettingManager.get_effect_setting("delete_effect")
    }
    # print('update', effect_level, editor_man.effects)

# ------------------------------------------------------------------
func _load_auto_open_file():
    var auto_open_recent = int(SettingManager.get_basic_setting('auto_open_recent'))
    if auto_open_recent:
        var recent_file = SettingManager.get_basic_setting('recent_file')
        var backup_file = SettingManager.get_basic_setting('backup_file')
        
        if recent_file:
            # 如果备份文件与最近文件相同，比较修改时间
            if backup_file == recent_file:
                var recent_time = FileAccess.get_modified_time(recent_file)
                var backup_time = FileAccess.get_modified_time(SettingManager.BACKUP_FILE)
                
                if backup_time > recent_time:
                    # 备份文件更新，加载备份
                    current_file_path = recent_file
                    file_manager.open_file(editor, SettingManager.BACKUP_FILE)
                    is_dirty = true
                    _update_title()
                    _update_char()
                    show_hint(':opened backup of %s' % current_file_path)
                    editor_man.set_caret_line(SettingManager.get_basic_setting('backup_caret_line'))
                    editor_man.set_caret_column(SettingManager.get_basic_setting('backup_caret_col'))


                else:
                    # 原文件更新，加载原文件
                    current_file_path = recent_file
                    file_manager.open_file(editor, current_file_path)
                    is_dirty = false
                    _update_title()
                    _update_char()
                    show_hint(':opened %s' % current_file_path)
            else:
                # 不同文件，直接加载最近文件
                current_file_path = recent_file
                file_manager.open_file(editor, current_file_path)
                is_dirty = false
                _update_title()
                _update_char()
                show_hint(':opened %s' % current_file_path)
        else:
            # 没有最近文件，加载备份
            current_file_path = ''
            file_manager.open_file(editor, SettingManager.BACKUP_FILE)
            is_dirty = true
            _update_title()
            _update_char()
            show_hint(':opened last untitled')
            editor_man.set_caret_line(SettingManager.get_basic_setting('backup_caret_line'))
            editor_man.set_caret_column(SettingManager.get_basic_setting('backup_caret_col'))
    else:
        current_file_path = ''
        is_dirty = false
        _update_title()
        _update_char()

# 当设置改变时更新自动保存
func _on_setting_changed():
    var auto_save = SettingManager.get_basic_setting("auto_save")
    if auto_save and not autosave_timer.is_stopped():
        autosave_timer.start(AUTOSAVE_INTERVAL)
    elif not auto_save:
        autosave_timer.stop()
    var show_char_count =  SettingManager.get_basic_setting("show_char_count")
    char_label.visible = show_char_count
    var line_wrap = SettingManager.get_basic_setting("line_wrap")
    if line_wrap:
        editor_man.editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    else:
        editor_man.editor.wrap_mode = TextEdit.LINE_WRAPPING_NONE
    var highlight_line =  SettingManager.get_basic_setting("highlight_line")
    editor_man.editor.highlight_current_line = highlight_line

    var font_size = SettingManager.get_basic_setting("font_size")
    match font_size:
        0: editor_man.editor.set("theme_override_font_sizes/font_size", 16)
        1: editor_man.editor.set("theme_override_font_sizes/font_size", 24)
        2: editor_man.editor.set("theme_override_font_sizes/font_size", 32)
        3: editor_man.editor.set("theme_override_font_sizes/font_size", 96)
    editor_man.update_gutter()
    editor_man.font_size = font_size
    editor_man.ime_display.font_size = font_size

    # 更新快捷键
    _update_editor_effects()
    _update_input_settings()
    _update_placeholder()

func _update_input_settings():

    # ime.page_size = SettingManager.get_ime_setting('page_size')
    ime_button.visible = SettingManager.get_ime_setting('show_icon')
    ime.update_settings(SettingManager.get_section_settings('ime'))

func _update_placeholder():
    editor_man.editor.placeholder_text = G.WRITER_PLACEHOLDER.format({
            new= '%-10s' % SettingManager.get_key_shown(SettingManager.get_setting("shortcut", "new_file")),
            open= '%-10s' % SettingManager.get_key_shown(SettingManager.get_setting("shortcut", "open_file")),
            save= '%-10s' % SettingManager.get_key_shown(SettingManager.get_setting("shortcut", "save_file")),
            setting= '%-10s' %  SettingManager.get_key_shown(SettingManager.get_setting("shortcut", "open_setting")),
        })
    
func _update_about_and_logs():
    settings.about.text = G.WRITER_ABOUT
    settings.logs.text = "".join(G.WRITER_LOGS)

# --------------------------
func _unhandled_input(event):
    if event.is_action_pressed("ui_cancel"):
        if settings.visible: _toggle_setting()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        event = event as InputEventKey
        var last_key = OS.get_keycode_string(event.get_keycode_with_modifiers())
        if SettingManager.is_match_shortcut(last_key, 'shortcut', 'save_file'):
            get_viewport().set_input_as_handled()
            if current_file_path == '':
                file_manager.show_save_dialog()
                current_file_path = await file_manager.file_selected
                if current_file_path:
                    SettingManager.set_recent(current_file_path)
                    _update_backup()
                else:
                    return
            file_manager.save_file(editor, current_file_path)
            is_dirty = false
            _update_title()
            show_hint(':saved %s' % current_file_path)
        elif SettingManager.is_match_shortcut(last_key, 'shortcut', 'open_file'):
            get_viewport().set_input_as_handled()
            file_manager.show_open_dialog(current_file_path)
            var file_path = await file_manager.file_selected
            if file_path:
                file_manager.open_file(editor, file_path)
                # file_manager.open_file(editor_man.editor_secondary, file_path)
                current_file_path = file_path
                show_hint(':opened %s' % current_file_path)
                SettingManager.set_recent(current_file_path)
                _update_backup()
                editor_man.update_editor_stats()
                is_dirty = false
                _update_title()
                _update_char()
        elif SettingManager.is_match_shortcut(last_key, 'shortcut', 'new_file'):
            _new_file()
        elif SettingManager.is_match_shortcut(last_key, 'shortcut', 'open_setting'):
            _toggle_setting()
            get_viewport().set_input_as_handled()
        elif SettingManager.is_match_shortcut(last_key, 'shortcut', 'switch_effect'):
            _toggle_effect()
            get_viewport().set_input_as_handled()

func _new_file():
    get_viewport().set_input_as_handled()
    
    # Add confirmation dialog if there are unsaved changes
    if is_dirty:
        var dialog = ConfirmationDialog.new()
        dialog.title = "当前文件未保存"
        dialog.dialog_text = "文件未保存。是否继续创建新文件？"
        dialog.ok_button_text = "创建"
        dialog.cancel_button_text = "取消"
        add_child(dialog)
        
        dialog.confirmed.connect(func():
            _create_new_file()
            dialog.queue_free()
        )
        
        dialog.canceled.connect(func():
            dialog.queue_free()
        )
        
        dialog.popup_centered()
    else:
        _create_new_file()

# Helper function to create new file
func _create_new_file():
    file_manager.new_file(editor)
    current_file_path = ''
    is_dirty = false
    _update_title()
    _update_char()
    show_hint(':created new file: untitled')
    SettingManager.set_recent(current_file_path)
    _update_backup()
    editor_man.update_editor_stats()

func set_title(file_path):
    DisplayServer.window_set_title(file_path)

func show_hint(txt):
    bottom_label.text = txt
    await get_tree().create_timer(4.0).timeout
    bottom_label.text = ''

func _toggle_setting():
    settings.visible = !settings.visible
    if settings.visible:
        ime.reset()
        ime.is_disabled = true
        editor_man.editor.editable = false
        editor_man.editor.release_focus()
        settings.tips.text = Rnd.pick(G.WRITER_TIPS)
    else:
        ime.is_disabled = false
        editor_man.editor.editable = true
        editor_man.editor.grab_focus()
func _toggle_effect():
    var efx = SettingManager.get_setting('effect', 'level')
    if efx:
        # editor_man._scf('VFX:off')
        await get_tree().process_frame
        SettingManager.set_setting('effect', 'level', 0)
        settings.effect_level.button_pressed = false
    else:
        SettingManager.set_setting('effect', 'level', 1)
        settings.effect_level.button_pressed = true
        # editor_man._scf('VFX:on')

func _on_typing():
    is_dirty = true
    _update_char()

func _on_autosave_timeout():
    if current_file_path != '' and is_dirty:
        file_manager.save_file(editor, current_file_path)
        show_hint(':autosaved %s' % current_file_path)
        is_dirty = false

func _on_backup_timeout():
    if is_dirty:
        _update_backup()
        SettingManager.set_setting_no_signal('basic', 'backup_caret_line', editor_man.editor.get_caret_line())
        SettingManager.set_setting_no_signal('basic', 'backup_caret_col', editor_man.editor.get_caret_column())
        
func _update_backup():
    file_manager.save_file(editor, SettingManager.BACKUP_FILE)
    SettingManager.set_backup(current_file_path)

func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        # 程序关闭时保存备份
        if is_dirty:
            file_manager.save_file(editor, SettingManager.BACKUP_FILE)
        get_tree().quit()

func _set_is_dirty(v):
    if is_dirty != v:
        is_dirty = v
        _update_title()

func _update_title():
    var d = '* ' if is_dirty else ''
    var f = current_file_path if current_file_path else 'Untitled'
    set_title(d+f)

func _update_char():
    char_label.text = '%dC' % editor_man.editor.text.length() 

# --------------------------------

func _on_files_dropped(files: PackedStringArray) -> void:
    var is_failed = true
    for file_path in files:
        # Check if the file is an txt
        if file_path.get_extension().to_lower() in DocumentManager.TXT_EXTS:
            current_file_path = file_path
            file_manager.open_file(editor, file_path)
            show_hint(':open dropped %s' % current_file_path)
            SettingManager.set_recent(current_file_path)
            _update_backup()
            editor_man.update_editor_stats()
            is_dirty = false
            _update_title()
            _update_char()
            return

    show_hint(':failed to open file, not txt extension')

