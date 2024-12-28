class_name ExecutionWindow
extends Window

signal execution_requested(command: String, args: Dictionary)
signal execution_canceled

@onready var input: LineEdit = $VBoxContainer/LineEdit
@onready var command_list: ItemList = $VBoxContainer/CommandList

var current_text: String = ""
var available_executors: Dictionary = {}

func _ready() -> void:
    # 设置窗口属性
    title = "Execute"
    size = Vector2(400, 200)
    unresizable = true
    exclusive = true
    
    # 初始化标签
    input.text = ""
    
    # 初始化命令列表
    setup_command_list()
    
    # 确保窗口可以接收输入
    set_process_input(true)
    
    # 设置标签可聚焦
    input.focus_mode = Control.FOCUS_ALL
    command_list.item_clicked.connect(_on_item_clicked)
    
    # 延迟一帧再获取焦点，确保窗口已完全创建
    await get_tree().process_frame
    input.grab_focus()

func set_available_executors(executors: Dictionary) -> void:
    available_executors = executors
    setup_command_list()

func setup_command_list() -> void:
    command_list.clear()
    for cmd in available_executors:
        command_list.add_item("%s - %s" % [cmd, available_executors[cmd].description])
    update_command_list("")

func update_command_list(filter_text: String) -> void:
    command_list.clear()

    var parts = filter_text.split(' ', true, 2)  # 最多分割成3部分
    var cmd_filter = parts[0]
    var arg_filter = parts[1] if parts.size() > 1 else ''
    var value = parts[2] if parts.size() > 2 else ''
    prints('cmd', cmd_filter, arg_filter, value)
    
    for cmd in available_executors:
        var executor = available_executors[cmd]
        
        # 如果命令有子命令且当前输入匹配该命令
        if executor.has("sub_commands") and cmd.begins_with(cmd_filter):
            # 如果已经输入了空格，显示子命令列表
            if arg_filter != "":
                # 存储匹配的子命令
                var matched_subcmds = []
                for sub_cmd in executor.sub_commands:
                    if sub_cmd.begins_with(arg_filter):
                        matched_subcmds.append(sub_cmd)
                
                # 如果有值部分，只显示之前匹配的子命令
                if value != "":
                    for sub_cmd in matched_subcmds:
                        command_list.add_item("%s %s %s" % [cmd, sub_cmd, value])
                # 否则显示所有匹配的子命令
                else:
                    for sub_cmd in matched_subcmds:
                        command_list.add_item("%s %s - %s" % [cmd, sub_cmd, executor.sub_commands[sub_cmd]])
            # 如果还没有输入空格，但已经开始输入命令
            else:
                # 显示所有子命令
                for sub_cmd in executor.sub_commands:
                    command_list.add_item("%s %s - %s" % [cmd, sub_cmd, executor.sub_commands[sub_cmd]])
        # 如果还在输入主命令且匹配当前过滤器
        elif cmd_filter.is_empty() or cmd.begins_with(cmd_filter):
            command_list.add_item("%s - %s" % [cmd, executor.description])
    
    if command_list.item_count > 0:
        command_list.select(0)
        command_list.ensure_current_is_visible()

func _input(event: InputEvent) -> void:
    if not input.has_focus(): return
        
    if event is InputEventKey and event.pressed:
        var key_name = event.as_text_keycode()
        if event.keycode == KEY_ESCAPE:
            emit_signal("execution_canceled")
            queue_free()
        elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            execute_command()
        elif event.keycode == KEY_BACKSPACE:
            current_text = current_text.substr(0, current_text.length()-1)
            if not current_text.is_empty():
                update_command_list(current_text)
        elif event.keycode == KEY_DOWN or key_name=='Ctrl+J':
            var next_idx = command_list.get_selected_items()[0] + 1 if command_list.get_selected_items().size() > 0 else 0
            if next_idx < command_list.item_count:
                command_list.select(next_idx)
                command_list.ensure_current_is_visible()
                update_current_text_from_selection()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_UP or key_name == 'Ctrl+K':
            var prev_idx = command_list.get_selected_items()[0] - 1 if command_list.get_selected_items().size() > 0 else 0
            if prev_idx >= 0:
                command_list.select(prev_idx)
                command_list.ensure_current_is_visible()
                update_current_text_from_selection()
            get_viewport().set_input_as_handled()
        else:
            var char_str = char(event.unicode)
            if event.unicode != 0:
                current_text += char_str
                update_command_list(current_text)

func update_current_text_from_selection() -> void:
    var selected = command_list.get_selected_items()
    if selected.size() > 0:
        var item_text = command_list.get_item_text(selected[0])
        current_text = item_text.split(" - ")[0]
        input.text = current_text
        input.caret_column = current_text.length()

func execute_command() -> void:
    var selected = command_list.get_selected_items()
    if selected.size() > 0:
        var item_text = command_list.get_item_text(selected[0])
        # 分割命令文本，但保留第三个参数
        var parts = current_text.split(" ", false)
        
        # 从选中项获取完整的命令名称和子命令
        var selected_parts = item_text.split(" ", false)
        var command = "setting" if selected_parts[0] == "se" else selected_parts[0]  # 使用完整命令名
        var args = {}
        
        # 处理子命令和其参数
        if parts.size() > 1:
            # 使用选中项中的完整子命令名称
            args["args"] = selected_parts[1]  # 使用完整的子命令名称
            if parts.size() > 2:
                args["value"] = parts[2]  # 子命令的参数值

        emit_signal("execution_requested", command, args)
    else:
        emit_signal("execution_canceled")
    queue_free()

func _on_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
    var item_text = command_list.get_item_text(index)
    var command = item_text.split(" - ")[0]
    emit_signal("execution_requested", command, {})
    queue_free() 
