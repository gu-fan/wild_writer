class_name MotionWindow
extends Window

signal command_executed(command: String)
signal command_canceled

@onready var label: Label = $Label
@onready var command_list: ItemList = $CommandList

var current_text: String = ""
var available_commands = {}
var viewport

# 添加正则表达式用于匹配数字前缀
var number_regex: RegEx

func _ready() -> void:
    # 设置窗口属性
    title = ""
    size = Vector2(400, 200)
    unresizable = true
    # exclusive = true
    always_on_top = true
    # popup_window = true
    borderless = true
    # borderless = true

    # set_ime_active(false)
    
    # 初始化正则表达式
    number_regex = RegEx.new()
    number_regex.compile("^(\\d+)(.*)$")
    
    # 初始化标签
    label = $Label
    label.text = ""
    
    # 初始化命令列表
    command_list = $CommandList
    command_list.clear()
    setup_command_list()

    command_list.item_clicked.connect(_on_item_clicked)
    close_requested.connect(_on_close_requested)

    # 确保窗口可以接收输入
    set_process_input(true)

    viewport = get_tree().current_scene.get_viewport()
    viewport.size_changed.connect(_on_viewport_resized)
    
    # 设置标签可聚焦
    label.focus_mode = Control.FOCUS_ALL
    
    # 延迟一帧再获取焦点，确保窗口已完全创建
    await get_tree().process_frame
    label.grab_focus()


func set_available_commands(commands: Dictionary) -> void:
    available_commands = commands
    setup_command_list()

func setup_command_list() -> void:
    if not command_list:
        return
    command_list.clear()
    for cmd in available_commands:
        command_list.add_item("%s - %s" % [cmd, available_commands[cmd].description])
    update_command_list("")

# func update_command_list(filter_text: String) -> void:
#     command_list.clear()
    
#     # 检查是否有数字前缀
#     var result = number_regex.search(filter_text)
#     var actual_filter = filter_text
    
#     if result:
#         # 保留数字前缀，但使用剩余部分进行过滤
#         var number = result.get_string(1)
#         var command_part = result.get_string(2)
#         actual_filter = command_part
    
#     for cmd in available_commands:
#         if actual_filter.is_empty() or cmd.begins_with(actual_filter):
#             # 如果有数字前缀，在显示时保留
#             if result:
#                 var number = result.get_string(1)
#                 command_list.add_item("%s%s - %s" % [number, cmd, available_commands[cmd].description])
#             else:
#                 command_list.add_item("%s - %s" % [cmd, available_commands[cmd].description])
    
#     # 如果有匹配项，选中第一个
#     if command_list.item_count > 0:
#         command_list.select(0)
#         command_list.ensure_current_is_visible()

func _input(event: InputEvent) -> void:
    # if not label.has_focus():
    #     return
        
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            _on_close_requested()
        elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            execute_command()
        elif event.keycode == KEY_BACKSPACE:
            if not current_text.is_empty():
                current_text = current_text.substr(0, current_text.length() - 1)
                label.text = current_text
                update_command_list(current_text)
        elif event.keycode == KEY_DOWN:
            # 移动到下一个命令
            var next_idx = command_list.get_selected_items()[0] + 1 if command_list.get_selected_items().size() > 0 else 0
            if next_idx < command_list.item_count:
                command_list.select(next_idx)
                command_list.ensure_current_is_visible()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_UP:
            # 移动到上一个命令
            var prev_idx = command_list.get_selected_items()[0] - 1 if command_list.get_selected_items().size() > 0 else 0
            if prev_idx >= 0:
                command_list.select(prev_idx)
                command_list.ensure_current_is_visible()
            get_viewport().set_input_as_handled()
        else:
            print('got key', event.unicode)
            # 处理普通字符输入
            var char_str = char(event.unicode)
            if event.unicode != 0 and char_str.strip_edges() != "":
                current_text += char_str
                label.text = current_text
                update_command_list(current_text)

func execute_command() -> void:
    var selected = command_list.get_selected_items()
    if selected.size() > 0:
        var item_text = command_list.get_item_text(selected[0])
        var command = item_text.split(" - ")[0]  # 获取命令部分
        emit_signal("command_executed", command)
    elif not current_text.is_empty():
        emit_signal("command_executed", current_text)
    queue_free()

func update_command_list(new_text: String) -> void:
    # Update command list based on input
    command_list.clear()
    
    # If input is empty, show all commands
    if new_text.is_empty():
        for command in available_commands:
            command_list.add_item(command + ": " + available_commands[command]["description"])
        return
    
    # Try to execute the command immediately if it matches exactly
    if available_commands.has(new_text):
        command_executed.emit(new_text)
        hide()
        return
    
    # Check for number prefix commands (e.g., "3j", "s3k")
    var regex = RegEx.new()
    regex.compile("^s?(\\d+)?([wbjkhl])$")
    var result = regex.search(new_text)
    if result:
        command_executed.emit(new_text)
        hide()
        return
    
    # Filter and show matching commands
    for command in available_commands:
        if command.begins_with(new_text):
            command_list.add_item(command + ": " + available_commands[command]["description"])

    # 如果有匹配项，选中第一个
    if command_list.item_count > 0:
        command_list.select(0)
        command_list.ensure_current_is_visible()

func _on_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
    if _mouse_button_index == 1:
        var item_text = command_list.get_item_text(index)
        var command = item_text.split(":")[0].strip_edges()
        command_executed.emit(command)
        hide()

func _on_close_requested() -> void:
    emit_signal("command_canceled")
    queue_free()

func _on_viewport_resized():
    var window_size = Vector2(size)
    var viewport_size = Vector2(get_tree().current_scene.get_viewport_rect().size)
    position = Vector2((viewport_size - window_size) / 2)
