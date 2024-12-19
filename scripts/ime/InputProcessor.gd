# scripts/ime/core/input_processor.gd
class_name InputProcessor

signal composition_updated
signal text_committed(text: String)

var context: CompositionContext
var matcher: PinyinMatcher

func _init(p_context: CompositionContext, p_matcher: PinyinMatcher):
    context = p_context
    matcher = p_matcher

func process_key(event: InputEventKey) -> bool:
    if not event.pressed:
        return false
        
    var key_string = OS.get_keycode_string(event.get_keycode_with_modifiers())
    
    # 处理特殊键
    match key_string:
        "Escape":
            return _handle_escape()
        "Enter", "Return":
            return _handle_enter()
        "Backspace":
            return _handle_backspace()
    
    # 处理数字键选择
    if _handle_number_selection(key_string):
        return true
    
    # 处理翻页
    if _handle_page_keys(key_string):
        return true
    
    # 处理拼音输入
    return _handle_pinyin_input(key_string)

# 处理Escape键
func _handle_escape() -> bool:
    if context.buffer.is_empty():
        return false
    context.reset()
    emit_signal("composition_updated")
    return true

# 处理Enter键
func _handle_enter() -> bool:
    if context.buffer.is_empty():
        return false
        
    # 如果有候选字，提交当前选中的字
    if not context.candidates.is_empty():
        var selected_text = context.candidates[context.current_selection]
        emit_signal("text_committed", selected_text)
        
        # 处理未匹配完的拼音
        var matched_length = context.candidates_matched_lengths[context.current_selection]
        if matched_length < context.buffer.length():
            # 保留未匹配的部分
            context.buffer = context.buffer.substr(matched_length)
            # 更新候选词列表
            matcher.update_candidates(context)
            emit_signal("composition_updated")
        else:
            # 完全匹配，重置上下文
            context.reset()
            emit_signal("composition_updated")
        return true
        
    # 如果没有候选字但有输入，直接提交输入
    emit_signal("text_committed", context.buffer)
    context.reset()
    emit_signal("composition_updated")
    return true

# 处理Backspace键
func _handle_backspace() -> bool:
    if context.buffer.is_empty():
        return false
        
    context.buffer = context.buffer.substr(0, context.buffer.length() - 1)
    matcher.update_candidates(context)
    emit_signal("composition_updated")
    return true

# 处理数字键选择
func _handle_number_selection(key: String) -> bool:
    # 检查是否是1-9的数字键
    if not key.length() == 1:
        return false
    var num = key.to_int()
    if num < 1 or num > 9:
        return false
        
    # 计算实际的候选词索引
    var index = num - 1 + context.current_page * context.page_size
    if index >= context.candidates.size():
        return false
        
    # 提交选中的字
    var selected_text = context.candidates[index]
    emit_signal("text_committed", selected_text)
    
    # 处理未匹配完的拼音
    var matched_length = context.candidates_matched_lengths[index]
    if matched_length < context.buffer.length():
        # 保留未匹配的部分
        context.buffer = context.buffer.substr(matched_length)
        # 更新候选词列表
        matcher.update_candidates(context)
        emit_signal("composition_updated")
    else:
        # 完全匹配，重置上下文
        context.reset()
        emit_signal("composition_updated")
    
    return true

# 处理翻页键
func _handle_page_keys(key: String) -> bool:
    match key:
        "," , "-", "Page_Up":  # 上一页
            if context.current_page > 0:
                context.current_page -= 1
                context.current_selection = 0
                emit_signal("composition_updated")
                return true
        "." , "=", "Page_Down":  # 下一页
            var total_pages = ceil(float(context.candidates.size()) / context.page_size)
            if context.current_page < total_pages - 1:
                context.current_page += 1
                context.current_selection = 0
                emit_signal("composition_updated")
                return true
    return false

# 处理拼音输入
func _handle_pinyin_input(key: String) -> bool:
    # 检查是否是有效的拼音字符
    if not _is_valid_pinyin_char(key.to_lower()):
        return false
        
    # 添加到输入缓冲区
    context.buffer += key.to_lower()
    
    # 更新候选词
    matcher.update_candidates(context)
    emit_signal("composition_updated")
    return true

# 辅助方法：检查是否是有效的拼音字符
func _is_valid_pinyin_char(char: String) -> bool:
    # 只允许英文字母
    return char.length() == 1 and char.is_valid_identifier()
