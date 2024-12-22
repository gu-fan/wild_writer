class_name ExecutionWindow
extends Window

signal execution_requested(command: String, args: Dictionary)

@onready var label: Label = $VBoxContainer/Label
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
    label.text = ""
    
    # 初始化命令列表
    setup_command_list()
    
    # 确保窗口可以接收输入
    set_process_input(true)
    
    # 设置标签可聚焦
    label.focus_mode = Control.FOCUS_ALL
    
    # 延迟一帧再获取焦点，确保窗口已完全创建
    await get_tree().process_frame
    label.grab_focus()

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
    
    for cmd in available_executors:
        if filter_text.is_empty() or cmd.begins_with(filter_text):
            command_list.add_item("%s - %s" % [cmd, available_executors[cmd].description])
    
    if command_list.item_count > 0:
        command_list.select(0)
        command_list.ensure_current_is_visible()

func _input(event: InputEvent) -> void:
    if not label.has_focus():
        return
        
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            queue_free()
        elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            execute_command()
        elif event.keycode == KEY_BACKSPACE:
            if not current_text.is_empty():
                current_text = current_text.substr(0, current_text.length() - 1)
                label.text = current_text
                update_command_list(current_text)
        elif event.keycode == KEY_DOWN:
            var next_idx = command_list.get_selected_items()[0] + 1 if command_list.get_selected_items().size() > 0 else 0
            if next_idx < command_list.item_count:
                command_list.select(next_idx)
                command_list.ensure_current_is_visible()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_UP:
            var prev_idx = command_list.get_selected_items()[0] - 1 if command_list.get_selected_items().size() > 0 else 0
            if prev_idx >= 0:
                command_list.select(prev_idx)
                command_list.ensure_current_is_visible()
            get_viewport().set_input_as_handled()
        else:
            var char_str = char(event.unicode)
            if event.unicode != 0 and char_str.strip_edges() != "":
                current_text += char_str
                label.text = current_text
                update_command_list(current_text)

func execute_command() -> void:
    var selected = command_list.get_selected_items()
    if selected.size() > 0:
        var item_text = command_list.get_item_text(selected[0])
        var command = item_text.split(" - ")[0]
        
        # 解析命令和参数
        var parts = current_text.split(" ", true, 1)
        var args = {}
        if parts.size() > 1:
            args["args"] = parts[1]
        
        emit_signal("execution_requested", command, args)
    queue_free()

func _on_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
    var item_text = command_list.get_item_text(index)
    var command = item_text.split(" - ")[0]
    emit_signal("execution_requested", command, {})
    queue_free() 
