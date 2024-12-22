class_name EditorMotions
extends RefCounted

var editor: Node  # 引用 EditorView 实例

var split_container: HSplitContainer
var primary_container: VBoxContainer
var secondary_container: VBoxContainer
var text_edit: CodeEdit
var text_edit_secondary: CodeEdit
var is_split_view: bool = false
var is_swapped_view: bool = false
var last_focused_editor: CodeEdit = null :
    set(v):
        editor.last_focused_editor = v
    get:
        return editor.last_focused_editor

func _init(editor_view: Node) -> void:
    editor = editor_view
    split_container = editor.split_container
    primary_container = editor.primary_container
    secondary_container = editor.secondary_container
    text_edit = editor.text_edit
    text_edit_secondary = editor.text_edit_secondary



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
    "vv": {
        "description": "Toggle split view",
        "action": "toggle_split"
    },
    "vn": {
        "description": "Go to next view",
        "action": "next_view"
    },
    "vc": {
        "description": "close view",
        "action": "close_view"
    },
    "vs": {
        "description": "swap view",
        "action": "swap_view"
    },
    "v1": {
        "description": "goto view 1",
        "action": "goto_view_1"
    },
    "v2": {
        "description": "goto view 2",
        "action": "goto_view_2"
    }
}

# 命令执行函数
func execute_command(command: String) -> void:
    print("Debug - Command received:", command)
    # # 解析命令中的数字前缀
    # var count = 1
    # var action_command = command
    
    # # 使用正则表达式匹配数字前缀
    # var regex = RegEx.new()
    # regex.compile("^(\\d+)(.+)$")
    # var result = regex.search(command)
    
    # if result:
    #     count = result.get_string(1).to_int()
    #     action_command = result.get_string(2)
    
    # if action_command in available_commands:
    #     var action = available_commands[action_command]["action"]
    #     call_action(action, count)
    
    # 解析命令中的数字前缀
    var count = 1
    var action_command = command
    
    # 使用正则表达式��配命令格式
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

        if cmd in available_commands:
            var action = available_commands[cmd]["action"]
            call_action(action, count)
        
        # # 判断是否是选择模式（以s开头）
        # if command.begins_with("s"):
        #     match cmd:
        #         "j":
        #             select_down(count)
        #         "k":
        #             select_up(count)
        #         "w":
        #             select_word_forward(count)
        #         "b":
        #             select_word_backward(count)
        # else:
        #     match cmd:
        #         "j":
        #             move_down(count)
        #         "k":
        #             move_up(count)
        #         "w":
        #             move_word_forward(count)
        #         "b":
        #             move_word_backward(count)
    else:
        if command in available_commands:
            var action = available_commands[command]["action"]
            call_action(action)
        # print('command', command)
        # if command in available_commands:
        #     match available_commands[command].action:
        #         'toggle_split': toggle_split_view()
        #         'next_view': next_view()
        #         'close_view': close_view()
        #         'swap_view': swap_view()
        #         'goto_view_1': goto_view(1)
        #         'goto_view_2': goto_view(2)

func call_action(action: String, count: int = 1) -> void:
    prints('Debug Call action', action ,count)
    match action:
        "move_down":
            move_down(count)
        "move_up":
            move_up(count)
        "move_word_forward":
            move_word_forward(count)
        "move_word_backward":
            move_word_backward(count)
        "select_down":
            select_down(count)
        "select_up":
            select_up(count)
        "select_word_forward":
            select_word_forward(count)
        "select_word_backward":
            select_word_backward(count)
        'toggle_split': toggle_split_view()
        'next_view': next_view()
        'close_view': close_view()
        'swap_view': swap_view()
        'goto_view_1': goto_view(1)
        'goto_view_2': goto_view(2)

# 具体的命令实现
func move_down(count: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_column = last_focused_editor.get_caret_column()
        var line_count = last_focused_editor.get_line_count()
        
        # 计算目标行，确保不超出文件范围
        var target_line = mini(current_line + count, line_count - 1)
        
        # 移动光标
        last_focused_editor.set_caret_line(target_line)
        last_focused_editor.set_caret_column(current_column)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

func move_up(count: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_column = last_focused_editor.get_caret_column()
        
        # 计算目标行，确保不小于0
        var target_line = maxi(current_line - count, 0)
        
        # 移动光标
        last_focused_editor.set_caret_line(target_line)
        last_focused_editor.set_caret_column(current_column)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

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
            
            # 从当前位置开始找下一个单词
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

func move_word_backward(count: int = 1) -> void:
    if last_focused_editor:
        for i in range(count):
            var current_line = last_focused_editor.get_caret_line()
            var current_column = last_focused_editor.get_caret_column()
            
            # 如果当前在行首，移动到上一行末尾
            if current_column == 0:
                if current_line > 0:
                    current_line -= 1
                    var line_text = last_focused_editor.get_line(current_line)
                    current_column = line_text.length()
                    last_focused_editor.set_caret_line(current_line)
                    last_focused_editor.set_caret_column(current_column)
                continue
            
            var line_text = last_focused_editor.get_line(current_line)
            var pos = current_column
            
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
            
            last_focused_editor.set_caret_column(pos)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

func select_down(count: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_col = last_focused_editor.get_caret_column()
        var target_line = mini(current_line + count, last_focused_editor.get_line_count() - 1)
        
        if not last_focused_editor.has_selection():
            # 从当前光标位置开始选择到目标行
            last_focused_editor.select(current_line, current_col,
                                         target_line, current_col)
        else:
            var start_line = last_focused_editor.get_selection_from_line()
            var start_col = last_focused_editor.get_selection_from_column()
            
            # 扩展选择，保持开始位置不变
            last_focused_editor.select(start_line, start_col,
                                         target_line, current_col)
        
        # 移动光标到选择区域的末尾
        last_focused_editor.set_caret_line(target_line)
        last_focused_editor.set_caret_column(current_col)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

func select_up(count: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_col = last_focused_editor.get_caret_column()
        var target_line = maxi(current_line - count, 0)
        
        if not last_focused_editor.has_selection():
            # 从当前光标位置开始选择到目标行
            last_focused_editor.select(current_line, current_col,
                                         target_line, current_col)
        else:
            var start_line = last_focused_editor.get_selection_from_line()
            var start_col = last_focused_editor.get_selection_from_column()
            
            # 扩展选择，保持开始位置不变
            last_focused_editor.select(start_line, start_col,
                                         target_line, current_col)
        
        # 移动光标到选择区域的开始
        last_focused_editor.set_caret_line(target_line)
        last_focused_editor.set_caret_column(current_col)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

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

func select_word_backward(count: int = 1) -> void:
    if last_focused_editor:
        var current_line = last_focused_editor.get_caret_line()
        var current_column = last_focused_editor.get_caret_column()
        
        if not last_focused_editor.has_selection():
            # 如果没有选择，从当前位置开始选择
            last_focused_editor.select(current_line, current_column,
                                         current_line, current_column)
        
        # 获取当前选择的开始位置
        var start_line = last_focused_editor.get_selection_from_line()
        var start_column = last_focused_editor.get_selection_from_column()
        
        # 移动到目标位置
        for i in range(count):
            var line_text = last_focused_editor.get_line(start_line)
            var pos = start_column
            
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
            
            start_column = pos
            
            # 如果到达行首，且不是第一行，移动到上一行末尾
            if start_column == 0 and start_line > 0:
                start_line -= 1
                line_text = last_focused_editor.get_line(start_line)
                start_column = line_text.length()
        
        # 更新选择区域
        last_focused_editor.select(start_line, start_column,
                                     last_focused_editor.get_selection_to_line(),
                                     last_focused_editor.get_selection_to_column())
        
        # 移动光标到选择区域的开始
        last_focused_editor.set_caret_line(start_line)
        last_focused_editor.set_caret_column(start_column)
        
        # 确保光标可见
        last_focused_editor.center_viewport_to_caret()

# 判断字符是否是单词分隔符
func is_word_separator(c: String) -> bool:
    # ASCII分隔符
    var ASCII_SEPARATORS = " \t\n.,;:!?\"'()[]{}<>/\\|`~@#$%^&*-+=_"
    # CJK分隔符
    var CJK_SEPARATORS = "。，、；：！？''（）【】《》／＼｜～＠＃￥％＾＆＊－＋＝＿「」『』〈〉《》〔〕［］｛｝"
    
    return c.strip_edges().is_empty() or c in ASCII_SEPARATORS or c in CJK_SEPARATORS

# ---------------------------------------

# 切换分屏
func toggle_split_view() -> void:
    is_split_view = !is_split_view
    if is_split_view:
        if secondary_container.visible:
            primary_container.show()
            last_focused_editor = text_edit
        else:
            secondary_container.show()
            last_focused_editor = text_edit_secondary
    else:
        # secondary_container.hide()
        if last_focused_editor == text_edit:
            secondary_container.hide()
        else:
            primary_container.hide()
    

func next_view() -> void:
    if is_split_view:
        if last_focused_editor == text_edit:
            last_focused_editor = text_edit_secondary
        else:
            last_focused_editor = text_edit

func close_view() -> void:
    if is_split_view:
        is_split_view = !is_split_view
        if last_focused_editor == text_edit:
            primary_container.hide()
            last_focused_editor = text_edit_secondary
        else:
            secondary_container.hide()
            last_focused_editor = text_edit

func swap_view() -> void:
    if is_split_view:
        # swap the child index of primary_container and secondary_container
        var secondary_index = secondary_container.get_index()
        split_container.move_child(primary_container, secondary_index)
        is_swapped_view = !is_swapped_view

func goto_view(n=1) -> void:
    if is_split_view:
        if n == 1:
            if is_swapped_view:
                last_focused_editor = text_edit_secondary
            else:
                last_focused_editor = text_edit
        else:
            if is_swapped_view:
                last_focused_editor = text_edit
            else:
                last_focused_editor = text_edit_secondary
