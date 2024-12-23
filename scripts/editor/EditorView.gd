class_name EditorView
extends Control

var core: EditorCore
var motions: EditorMotions
var executions: EditorExecutions

@onready var split_container: HSplitContainer = $SplitContainer
@onready var primary_container: VBoxContainer = $SplitContainer/PrimaryContainer
@onready var secondary_container: VBoxContainer = $SplitContainer/SecondaryContainer
@onready var text_edit: TextEdit = $SplitContainer/PrimaryContainer/TextEdit
@onready var text_edit_secondary: TextEdit = $SplitContainer/SecondaryContainer/TextEdit
@onready var status_bar: Label = $StatusBar

var last_focused_editor: TextEdit = null
var current_file_path: String = ""
var current_command_window: CommandWindow = null
var current_execution_window: ExecutionWindow = null
var current_file_dialog: FileDialog = null

func _ready():
    
    core = EditorCore.new()
    add_child(core)
    
    # 初始化命令系统
    motions = EditorMotions.new(self)
    executions =  EditorExecutions.new(self)
    
    # 初始化视图
    setup_view()
    # 连接信号
    connect_signals()
    # 设置快捷键
    setup_key_bindings()
    
    # 检查是否需要自动打开最近的文件
    if core.config_manager.get_basic_setting("auto_open_recent"):
        var recent_file = core.config_manager.get_basic_setting("recent_file")
        if recent_file and FileAccess.file_exists(recent_file):
            open_document_from_path(recent_file)
            
            # 恢复光标位置
            var caret_line = core.config_manager.get_basic_setting("backup_caret_line")
            var caret_col = core.config_manager.get_basic_setting("backup_caret_col")
            if last_focused_editor:
                last_focused_editor.set_caret_line(caret_line)
                last_focused_editor.set_caret_column(caret_col)
                last_focused_editor.center_viewport_to_caret()

func setup_view() -> void:
    # 设置编辑器基本属性
    text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY if core.config_manager.get_basic_setting("line_wrap") else TextEdit.LINE_WRAPPING_NONE
    text_edit.gutters_draw_line_numbers = core.config_manager.get_basic_setting("line_number")
    text_edit.highlight_current_line = core.config_manager.get_basic_setting("highlight_line")
    
    text_edit_secondary.wrap_mode = text_edit.wrap_mode
    text_edit_secondary.gutters_draw_line_numbers = text_edit.gutters_draw_line_numbers
    text_edit_secondary.highlight_current_line = text_edit.highlight_current_line
    
    # 初始隐藏第二编辑器
    primary_container.hide()

func connect_signals() -> void:
    text_edit.focus_entered.connect(_on_editor_focus_entered.bind(text_edit))
    text_edit_secondary.focus_entered.connect(_on_editor_focus_entered.bind(text_edit_secondary))

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
    core.key_system.sequence_matched.connect(_on_key_sequence_matched)

func _on_key_sequence_matched(binding: KeySystem.KeyBinding) -> void:
    print("Debug - Key sequence matched:", binding.command)
    match binding.command:
        "show_command": show_command_window()
        "show_execution": show_execution_window()

func _on_editor_focus_entered(editor: TextEdit) -> void:
    last_focused_editor = editor

func show_command_window() -> void:
    if current_command_window != null and is_instance_valid(current_command_window):
        return
    
    last_focused_editor = text_edit if text_edit.has_focus() else text_edit_secondary if text_edit_secondary.has_focus() else null
    
    current_command_window = preload("res://scenes/command_window.tscn").instantiate()
    current_command_window.set_available_commands(motions.available_commands)
    add_child(current_command_window)
    
    await get_tree().process_frame
    
    var window_size = Vector2(400, 200)
    var viewport_size = get_viewport_rect().size
    current_command_window.position = Vector2i((viewport_size - window_size) / 2)
    
    current_command_window.command_executed.connect(_on_command_executed)
    
    if last_focused_editor:
        last_focused_editor.get_window().set_ime_active(false)

func _on_command_executed(command: String) -> void:
    motions.execute_command(command)
    
    current_command_window = null
    
    if last_focused_editor:
        last_focused_editor.get_window().set_ime_active(true)
        last_focused_editor.grab_focus()

# 文件操作相关函数
func open_document_from_path(path: String) -> void:
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
        status_bar.text = "Opened: " + path

func save_document() -> void:
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
        status_bar.text = "Saved: " + current_file_path

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

# 执行窗口相关函数
func show_execution_window() -> void:
    if current_execution_window != null and is_instance_valid(current_execution_window):
        return
    
    last_focused_editor = text_edit if text_edit.has_focus() else text_edit_secondary if text_edit_secondary.has_focus() else null
    
    current_execution_window = preload("res://scenes/execution_window.tscn").instantiate()
    add_child(current_execution_window)
    current_execution_window.set_available_executors(executions.available_executors)
    
    await get_tree().process_frame
    
    var window_size = Vector2(400, 200)
    var viewport_size = get_viewport_rect().size
    current_execution_window.position = Vector2i((viewport_size - window_size) / 2)
    
    current_execution_window.execution_requested.connect(_on_execution_requested)
    
    if last_focused_editor:
        last_focused_editor.get_window().set_ime_active(false)

func _on_execution_requested(command: String, args: Dictionary):
    executions.execute_command(command, args)
    current_execution_window = null
    
    if last_focused_editor:
        last_focused_editor.get_window().set_ime_active(true)
        last_focused_editor.grab_focus()
