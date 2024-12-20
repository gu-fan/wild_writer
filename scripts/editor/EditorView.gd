class_name EditorView
extends Control

var core: EditorCore

# 分隔符定义
var ASCII_SEPARATORS = " \t\n.,;:!?\"'()[]{}<>/\\|`~@#$%^&*-+=_"
var CJK_SEPARATORS = "。，、；：！？''（）【】《》／＼｜～＠＃￥％＾＆＊－＋＝＿「」『』〈〉《》〔〕［］｛｝"

@onready var split_container: HSplitContainer = $SplitContainer
@onready var primary_container: VBoxContainer = $SplitContainer/PrimaryContainer
@onready var secondary_container: VBoxContainer = $SplitContainer/SecondaryContainer
@onready var text_edit: CodeEdit = $SplitContainer/PrimaryContainer/TextEdit
@onready var text_edit_secondary: CodeEdit = $SplitContainer/SecondaryContainer/TextEdit
@onready var status_bar: Label = $StatusBar

var is_split_view: bool = false
var current_file_dialog: FileDialog = null  # 添加文件对话框引用
var current_command_window: CommandWindow = null
var last_focused_editor: CodeEdit = null  # 添加变量记录上一个焦点编辑器
var current_file_path: String = ""  # 添加当前文件路径变量

# 添加命令定义
var available_commands = {
    "j": {
        "description": "Move down",
        "action": "move_down"
    },
    "k": {
        "description": "Move up",
        "action": "move_up"
    },
    "w": {
        "description": "Move to next word",
        "action": "move_word_forward"
    },
    "b": {
        "description": "Move to previous word",
        "action": "move_word_backward"
    },
    "s": {
        "description": "Start selection mode",
        "action": "select"
    },
    "sj": {
        "description": "Select lines down",
        "action": "select_down"
    },
    "sk": {
        "description": "Select lines up",
        "action": "select_up"
    },
    "sw": {
        "description": "Select words forward",
        "action": "select_word_forward"
    },
    "sb": {
        "description": "Select words backward",
        "action": "select_word_backward"
    },
    "O": {
        "description": "Open file",
        "action": "open"
    },
    "S": {
        "description": "Save file",
        "action": "save"
    },
    "v": {
        "description": "Toggle split view",
        "action": "toggle_split"
    },
    "f": {
        "description": "Find in file",
        "action": "find"
    }
}

func _ready():
    core = EditorCore.new()
    add_child(core)
    
    # 初始化视图
    setup_view()
    # 连接信号
    connect_signals()
    # 设置命令处理器和快捷键
    setup_commands()
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

func setup_key_bindings() -> void:
    # 命令窗口快捷键
    core.key_system.add_binding(
        ["Ctrl+E"],
        "show_command",
        "editorFocus"
    )
    
    # 文件操作快捷键
    core.key_system.add_binding(
        ["Ctrl+O"],
        "open",
        "editorFocus"
    )
    
    core.key_system.add_binding(
        ["Ctrl+S"],
        "save",
        "editorFocus"
    )
    
    # 连接按键系统信号
    core.key_system.sequence_matched.connect(_on_key_sequence_matched)

func _on_key_sequence_matched(binding: KeySystem.KeyBinding) -> void:
    print("Debug - Key sequence matched:", binding.command)
    match binding.command:
        "show_command":
            show_command_window()
        "open":
            open_document()
        "save":
            save_document()
        "toggle_split":
            toggle_split_view()

func show_command_window() -> void:
    # 如果已有窗口，就返回
    if current_command_window != null and is_instance_valid(current_command_window):
        return
    
    # 保存当前焦点编辑器
    last_focused_editor = text_edit if text_edit.has_focus() else text_edit_secondary if text_edit_secondary.has_focus() else null
    
    # 创建命令窗口
    current_command_window = preload("res://scenes/command_window.tscn").instantiate()
    
    # 设置可用命令
    current_command_window.set_available_commands(available_commands)
    
    add_child(current_command_window)
    
    # 等待帧确保窗口已完全初始化
    await get_tree().process_frame
    
    # 设置位置（居中）
    var window_size = Vector2(400, 200)  # 使用固定大小
    var viewport_size = get_viewport_rect().size
    current_command_window.position = Vector2i((viewport_size - window_size) / 2)
    
    # 连接信号
    current_command_window.command_executed.connect(_on_command_executed)
    current_command_window.close_requested.connect(_on_command_window_closed)
    
    # 关闭编辑器的 IME
    if last_focused_editor:
        last_focused_editor.get_window().set_ime_active(false)

func _on_command_executed(command: String) -> void:
    print("Debug - Command received:", command)
    
    # 解析命令中的数字前缀
    var count = 1
    var action_command = command
    
    # 使用正则表达式匹配命令格式
    var regex = RegEx.new()
    regex.compile("^s?(\\d+)?([wbjk])$")  # 添加b到命令匹配
    var result = regex.search(command)
    
    print("Debug - Regex match result:", result)
    
    if result:
        # 获取数字前缀（如果存在）
        var number = result.get_string(1)
        print("Debug - Number prefix:", number)
        if number:
            count = number.to_int()
        
        # 获取实际命令（j、k、w或b）
        var cmd = result.get_string(2)
        print("Debug - Command part:", cmd)
        
        # 判断是否是选择模式（以s开头）
        if command.begins_with("s"):
            match cmd:
                "j":
                    select_down(count)
                "k":
                    select_up(count)
                "w":
                    select_word_forward(count)
                "b":
                    select_word_backward(count)
        else:
            match cmd:
                "j":
                    move_down(count)
                "k":
                    move_up(count)
                "w":
                    move_word_forward(count)
                "b":
                    move_word_backward(count)
    
    # 关闭命令窗口
    if current_command_window:
        current_command_window.queue_free()
        current_command_window = null
    
    # 恢复编辑器焦点和 IME
    if last_focused_editor:
        last_focused_editor.get_window().set_ime_active(true)
        last_focused_editor.grab_focus()

func _on_command_window_closed() -> void:
    current_command_window = null
    
    # 恢复编辑器焦点和 IME
    if last_focused_editor:
        last_focused_editor.get_window().set_ime_active(true)
        last_focused_editor.grab_focus()

func setup_view() -> void:
    # 初始化隐藏第二视图
    secondary_container.hide()
    # 设置分割器
    split_container.split_offset = 0
    # 设置编辑器属性
    for editor in [text_edit, text_edit_secondary]:
        setup_editor(editor)

func setup_editor(editor: CodeEdit) -> void:
    editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    editor.highlight_current_line = true
    editor.minimap_draw = true
    editor.caret_blink = true
    editor.gutters_draw_line_numbers = true
    editor.gui_input.connect(_on_editor_gui_input.bind(editor))  # 添加输入处理

func connect_signals() -> void:
    core.document_changed.connect(_on_document_changed)
    core.editor_state_changed.connect(_on_editor_state_changed)
    
    # 连接编辑器信号
    text_edit.text_changed.connect(_on_text_changed.bind(text_edit))
    text_edit_secondary.text_changed.connect(_on_text_changed.bind(text_edit_secondary))

func setup_commands() -> void:
    core.command_manager.register_command("save", save_document)
    core.command_manager.register_command("open", open_document)
    core.command_manager.register_command("toggle_split", toggle_split_view)
    # ... 其他命令

# 切换分屏
func toggle_split_view() -> void:
    is_split_view = !is_split_view
    if is_split_view:
        secondary_container.show()
        # 如果主图有文，复制到第二视图
        if core.document_manager.active_document:
            text_edit_secondary.text = text_edit.text
    else:
        secondary_container.hide()
    
    # 添加调试输出
    print("Toggle split view:", is_split_view)

# 处理文档变化
func _on_document_changed(doc: DocumentManager.Document, target_editor: CodeEdit = text_edit) -> void:
    target_editor.text = doc.content
    status_bar.text = doc.file_path if doc.file_path else "Untitled"

# 处理文本变化
func _on_text_changed(editor: CodeEdit) -> void:
    var doc = core.document_manager.active_document
    if doc and editor == text_edit:  # 处理主编辑器的变化
        doc.content = editor.text

# 处理编辑器状态变化
func _on_editor_state_changed(state: Dictionary) -> void:
    # 对两个编辑器都应用设置
    for editor in [text_edit, text_edit_secondary]:
        match state.key:
            "font_size":
                editor.add_theme_font_size_override("font_size", state.value)
            "wrap_mode":
                editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY if state.value else TextEdit.LINE_WRAPPING_NONE
            "highlight_line":
                editor.highlight_current_line = state.value

# 保存文档
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

# 打开文档
func open_document(target_editor: CodeEdit = text_edit) -> void:
    # 如果已有对话框打开，就返回
    if current_file_dialog != null and is_instance_valid(current_file_dialog):
        return
        
    current_file_dialog = FileDialog.new()
    current_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    current_file_dialog.add_filter("*.txt;*.md;*.json", "Text files")
    current_file_dialog.add_filter("*", "All files")
    
    # 设置对话框大小和标题
    current_file_dialog.title = "Open File"
    current_file_dialog.size = Vector2(800, 600)
    
    add_child(current_file_dialog)
    current_file_dialog.popup_centered()
    
    # 等待文件选择
    var file_path = await current_file_dialog.file_selected
    current_file_dialog.queue_free()
    current_file_dialog = null  # 清除引用
    
    if file_path:
        var doc = core.document_manager.open_document(file_path)
        if doc:
            _on_document_changed(doc, target_editor)
            status_bar.text = "Opened: " + file_path
        else:
            status_bar.text = "Failed to open: " + file_path

# 处理编辑器的输入事件
func _on_editor_gui_input(event: InputEvent, editor: CodeEdit) -> void:
    if event is InputEventKey and event.pressed:
        # 如果按下了 Ctrl 键，处理输入
        if event.ctrl_pressed:
            return
            
        # 直接处理按键输入
        if event.unicode != 0:
            editor.insert_text_at_caret(char(event.unicode))
        else:
            # 处理特殊按键（如退格、回车等）
            match event.keycode:
                KEY_BACKSPACE:
                    editor.backspace()
                KEY_ENTER:
                    editor.insert_text_at_caret("\n")
                KEY_TAB:
                    editor.insert_text_at_caret("\t")
                KEY_DELETE:
                    editor.delete()

# 添加新的命令处理函数
func close_document() -> void:
    # TODO: 实现关闭文档功能
    pass

func find_in_file() -> void:
    # TODO: 实现查找功能
    pass

# 修改移动光标函数以支持行数
func move_down(lines: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_column = last_focused_editor.get_caret_column()
        var line_count = last_focused_editor.get_line_count()
        
        # 计算目标行，确保超出文本范围
        var target_line = mini(current_line + lines, line_count - 1)
        
        # 移动光标
        last_focused_editor.set_caret_line(target_line)
        # 尝试保持相同的列位置
        last_focused_editor.set_caret_column(current_column)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

# 添加向上移动函数
func move_up(lines: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_column = last_focused_editor.get_caret_column()
        
        # 计算目标行，确保不小于0
        var target_line = maxi(current_line - lines, 0)
        
        # 移动光标
        last_focused_editor.set_caret_line(target_line)
        # 尝试保持相同的列位置
        last_focused_editor.set_caret_column(current_column)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

# 添加选择函数
func select_down(lines: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_col = last_focused_editor.get_caret_column()
        var target_line = mini(current_line + lines, last_focused_editor.get_line_count() - 1)
        
        print("Debug - Initial state:")
        print("  Current line:", current_line)
        print("  Current col:", current_col)
        print("  Target line:", target_line)
        print("  Has selection:", last_focused_editor.has_selection())
        
        if not last_focused_editor.has_selection():
            print("Debug - Creating new selection:")
            print("  From line:", current_line)
            print("  To line:", target_line)
            # 从当前光标位置开始选择
            last_focused_editor.select(current_line, current_col,
                                    target_line, last_focused_editor.get_line(target_line).length())
        else:
            print("Debug - Extending existing selection:")
            var start_line = last_focused_editor.get_selection_from_line()
            var start_col = last_focused_editor.get_selection_from_column()
            target_line = mini(last_focused_editor.get_selection_to_line() + lines, 
                             last_focused_editor.get_line_count() - 1)
            
            print("  Start line:", start_line)
            print("  Start col:", start_col)
            print("  New target line:", target_line)
            
            last_focused_editor.select(start_line, start_col,
                                    target_line, last_focused_editor.get_line(target_line).length())
        
        # 移动光标到选择区域的末尾
        last_focused_editor.set_caret_line(target_line)
        last_focused_editor.set_caret_column(last_focused_editor.get_line(target_line).length())
        
        print("Debug - Final state:")
        print("  Selection from line:", last_focused_editor.get_selection_from_line())
        print("  Selection to line:", last_focused_editor.get_selection_to_line())
        print("  Caret line:", last_focused_editor.get_caret_line())
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

func select_up(lines: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_col = last_focused_editor.get_caret_column()
        var target_line = maxi(current_line - lines, 0)
        
        print("Debug - Initial state (select_up):")
        print("  Current line:", current_line)
        print("  Current col:", current_col)
        print("  Target line:", target_line)
        print("  Has selection:", last_focused_editor.has_selection())
        
        if not last_focused_editor.has_selection():
            print("Debug - Creating new selection:")
            print("  From line:", target_line)
            print("  To line:", current_line)
            # 从当前光标位置开始选择到目标行
            last_focused_editor.select(current_line, current_col,
                                    target_line, 0)
        else:
            print("Debug - Extending existing selection:")
            var end_line = last_focused_editor.get_selection_to_line()
            var end_col = last_focused_editor.get_selection_to_column()
            target_line = maxi(current_line - lines, 0)
            
            print("  End line:", end_line)
            print("  End col:", end_col)
            print("  New target line:", target_line)
            
            # 扩展选择，保持结束位置不变
            last_focused_editor.select(end_line, end_col,
                                    target_line, 0)
        
        # 移动光标到选择区域的开始
        last_focused_editor.set_caret_line(target_line)
        last_focused_editor.set_caret_column(0)
        
        print("Debug - Final state:")
        print("  Selection from line:", last_focused_editor.get_selection_from_line())
        print("  Selection to line:", last_focused_editor.get_selection_to_line())
        print("  Caret line:", last_focused_editor.get_caret_line())
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

# 添加向后移动一个单词的函数
func move_word_forward(count: int = 1) -> void:
    if last_focused_editor:
        for i in range(count):
            var current_line = last_focused_editor.get_caret_line()
            var current_column = last_focused_editor.get_caret_column()
            var line_text = last_focused_editor.get_line(current_line)
            
            # 如果当前在行尾，移动到下一行开始
            if current_column >= line_text.length():
                if current_line < last_focused_editor.get_line_count() - 1:
                    last_focused_editor.set_caret_line(current_line + 1)
                    last_focused_editor.set_caret_column(0)
                continue
            
            # 从当前位置开始找下一个单
            var pos = current_column
            var line_length = line_text.length()
            
            # 跳过当前单词的剩余部分
            while pos < line_length and not is_word_separator(line_text[pos]):
                pos += 1
            
            # 跳过空白字符
            while pos < line_length and is_word_separator(line_text[pos]):
                pos += 1
            
            # 如果找到了新位置
            if pos < line_length:
                last_focused_editor.set_caret_column(pos)
            # 如果到达行尾，且不是最后一行，移动到下一行开始
            elif current_line < last_focused_editor.get_line_count() - 1:
                last_focused_editor.set_caret_line(current_line + 1)
                last_focused_editor.set_caret_column(0)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

# 判断字符是否是单词分隔符
func is_word_separator(c: String) -> bool:
    # 白字符和标点符号都被视为分隔符
    return c.strip_edges().is_empty() or c in ASCII_SEPARATORS or c in CJK_SEPARATORS

# 添加选择单词的函数
func select_word_forward(count: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_column = last_focused_editor.get_caret_column()
        
        if not last_focused_editor.has_selection():
            # 如果没有选择，从当前位置开始选择
            last_focused_editor.select(current_line, current_column,
                                    current_line, current_column)
        
        # 获取当前选择的结束位置
        var end_line = last_focused_editor.get_selection_to_line()
        var end_column = last_focused_editor.get_selection_to_column()
        
        # 移动到目标位置
        for i in range(count):
            var line_text = last_focused_editor.get_line(end_line)
            var pos = end_column
            var line_length = line_text.length()
            
            # 如果当前在尾，移动到下一行开始
            if pos >= line_length:
                if end_line < last_focused_editor.get_line_count() - 1:
                    end_line += 1
                    end_column = 0
                continue
            
            # 跳过当前单词的剩余部分
            while pos < line_length and not is_word_separator(line_text[pos]):
                pos += 1
            
            # 跳过空白字符
            while pos < line_length and is_word_separator(line_text[pos]):
                pos += 1
            
            # 如果找到了新位置
            if pos < line_length:
                end_column = pos
            # 如果到达行尾，且不是最后一行，移动到下一行开始
            elif end_line < last_focused_editor.get_line_count() - 1:
                end_line += 1
                end_column = 0
        
        # 更新选择区域
        last_focused_editor.select(last_focused_editor.get_selection_from_line(),
                                last_focused_editor.get_selection_from_column(),
                                end_line, end_column)
        
        # 移动光标到选择区域的末尾
        last_focused_editor.set_caret_line(end_line)
        last_focused_editor.set_caret_column(end_column)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

# 添加向前移动到上一个单词的函数
func move_word_backward(count: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_column = last_focused_editor.get_caret_column()
        
        for i in range(count):
            var line_text = last_focused_editor.get_line(current_line)
            var pos = current_column
            
            # 如果当前在行首，移动到上一行末尾
            if pos == 0:
                if current_line > 0:
                    current_line -= 1
                    line_text = last_focused_editor.get_line(current_line)
                    pos = line_text.length()
                    # 如果上一行末尾是空白字符，跳过它们
                    while pos > 0 and is_word_separator(line_text[pos - 1]):
                        pos -= 1
                    # 移动到单词末尾
                    if pos > 0:
                        current_column = pos
                        continue
                continue
            
            # 如果在单词中间或末尾，先移动到单词开头
            if pos > 0 and not is_word_separator(line_text[pos - 1]):
                while pos > 0 and not is_word_separator(line_text[pos - 1]):
                    pos -= 1
            else:
                # 跳过空白字符
                while pos > 0 and is_word_separator(line_text[pos - 1]):
                    pos -= 1
                # 跳到上一个单词的开头
                while pos > 0 and not is_word_separator(line_text[pos - 1]):
                    pos -= 1
            
            current_column = pos
        
        # 更新光标位置
        last_focused_editor.set_caret_line(current_line)
        last_focused_editor.set_caret_column(current_column)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

# 添加向前选择单词的函数
func select_word_backward(count: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_column = last_focused_editor.get_caret_column()
        
        # 如果没有选择，从当前位置开始选择
        if not last_focused_editor.has_selection():
            last_focused_editor.select(current_line, current_column,
                                    current_line, current_column)
        
        # 获取当前选择的开始位置
        var from_line = last_focused_editor.get_selection_from_line()
        var from_column = last_focused_editor.get_selection_from_column()
        var to_line = last_focused_editor.get_selection_to_line()
        var to_column = last_focused_editor.get_selection_to_column()
        
        # 根据光标位置决定如何扩展选择
        var is_selecting_forward = current_line == to_line and current_column == to_column
        var target_line = current_line
        var target_column = current_column
        
        # 移动到目标位置
        for i in range(count):
            var line_text = last_focused_editor.get_line(target_line)
            var pos = target_column
            
            # 如果当前在行首，移动到上一行末尾
            if pos == 0:
                if target_line > 0:
                    target_line -= 1
                    line_text = last_focused_editor.get_line(target_line)
                    pos = line_text.length()
                    # 如果上一行末尾是空白字符，跳过它们
                    while pos > 0 and is_word_separator(line_text[pos - 1]):
                        pos -= 1
                    # 移动到单词末尾
                    if pos > 0:
                        target_column = pos
                        continue
                continue
            
            # 如果在单词中间或末尾，先移动到单词开头
            if pos > 0 and not is_word_separator(line_text[pos - 1]):
                while pos > 0 and not is_word_separator(line_text[pos - 1]):
                    pos -= 1
            else:
                # 跳过空白字符
                while pos > 0 and is_word_separator(line_text[pos - 1]):
                    pos -= 1
                # 跳到上一个单词的开头
                while pos > 0 and not is_word_separator(line_text[pos - 1]):
                    pos -= 1
            
            target_column = pos
        
        # 更新选择区域
        if is_selecting_forward:
            # 如果光标在选择区域的末尾，更新末尾位置
            last_focused_editor.select(from_line, from_column,
                                    target_line, target_column)
            # 移动光标到选择区域的末尾
            last_focused_editor.set_caret_line(target_line)
            last_focused_editor.set_caret_column(target_column)
        else:
            # 如果光标在选择区域的开始，更新开始位置
            last_focused_editor.select(target_line, target_column,
                                    to_line, to_column)
            # 移动光标到选择区域的开始
            last_focused_editor.set_caret_line(target_line)
            last_focused_editor.set_caret_column(target_column)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

# 在打开文件时更新最近文件记录
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

# 另存为文档
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
