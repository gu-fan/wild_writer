extends Node

signal ime_text_changed(text: String)
signal ime_state_changed(v)

var pinyin_buffer: String = ""
var candidates: Array = []
var candidates_matched_lengths: Array = []
var current_selection: int = 0
var is_ime_active: bool = false
var disabled: bool = false

# 简单的拼音到汉字的映射字典
var pinyin_dict = {}

# 修改频率字典的结构，使用 {char: {pinyin: freq}} 的形式
var char_frequencies: Dictionary = {}

var page_size: int = 5
var current_page: int = 0

# 添加字母缓存字典
var pinyin_dict_cache = {}

func _ready():
    load_pinyin_dict()
    build_pinyin_cache()
    load_settings()
    SettingManager.setting_changed.connect(load_settings)

func load_settings():
    page_size =  SettingManager.get_ime_setting('page_size')
    

func load_pinyin_dict():
    var file = FileAccess.open("res://scripts/google_pinyin.txt", FileAccess.READ)
    if not file:
        print("Failed to load pinyin dictionary")
        return
    
    while !file.eof_reached():
        var line = file.get_line().strip_edges()
        if line.is_empty() or line.begins_with("#"):
            continue
            
        var parts = line.split(" ", false, 3)
        if parts.size() < 4:
            continue
            
        var char = parts[0]          # 汉字
        var freq = parts[1].to_float() # 频率
        var is_rare = parts[2] == "1" # 是否罕见
        var pinyin = parts[3]         # 拼音
        
        if is_rare:
            continue

        # 移除拼音中的空格
        pinyin = pinyin.replace(" ", "")
        
        # 存储汉字在特定拼音下的频率
        if not char_frequencies.has(char):
            char_frequencies[char] = {}
        char_frequencies[char][pinyin] = freq
        
        # 添加到字典
        if not pinyin_dict.has(pinyin):
            pinyin_dict[pinyin] = []
        pinyin_dict[pinyin].append(char)

func build_pinyin_cache():
    # 初始化26个字母的缓存
    for ascii in range(97, 123):  # a-z的ASCII码
        var letter = char(ascii)
        pinyin_dict_cache[letter] = []
    
    # 将拼音按首字母分类
    for pinyin in pinyin_dict:
        var first_letter = pinyin[0]
        if first_letter in pinyin_dict_cache:
            pinyin_dict_cache[first_letter].append(pinyin)

func _input(event: InputEvent) -> void:
    if disabled: return
    if not is_ime_active:
        return
        
    if event is InputEventKey and event.pressed:
        handle_key_input(event)

func handle_key_input(event: InputEventKey) -> void:
    var key_string = OS.get_keycode_string(event.get_keycode_with_modifiers())
    
    # 处理特殊键
    match key_string:
        "Escape":  # 取消输入
            reset_ime()
            get_viewport().set_input_as_handled()
            return
        "Enter", "Return":  # 回车键处理
            if pinyin_buffer.length() > 0:
                if candidates.size() > 0:
                    # 有候选词时输入第一个
                    # emit_signal("ime_text_changed", candidates[0])
                    handle_candidate_selection(0)
                else:
                    # 没有候选词时直接输入拼音
                    emit_signal("ime_text_changed", pinyin_buffer)
                    reset_ime()
                get_viewport().set_input_as_handled()
                return
        "Backspace":  # 删除字符
            if pinyin_buffer.length() > 0:
                pinyin_buffer = pinyin_buffer.substr(0, pinyin_buffer.length() - 1)
                if pinyin_buffer.length() == 0:
                    reset_ime()
                else:
                    update_candidates()
                get_viewport().set_input_as_handled()
                return
        "BracketLeft":  # < 键，上一页
            if !pinyin_buffer.is_empty():
                get_viewport().set_input_as_handled()
            if current_page > 0:
                current_page -= 1
                return
        "BracketRight":  # > 键，下一页
            if !pinyin_buffer.is_empty():
                get_viewport().set_input_as_handled()
            if (current_page + 1) * page_size < candidates.size():
                current_page += 1
                return
    
    # Handle number keys for selection (1-5)
    if candidates.size() > 0 and key_string.is_valid_int():
        var num = key_string.to_int() - 1  # Convert to 0-based index
        var actual_index = current_page * page_size + num
        if num >= 0 and num < page_size and actual_index < candidates.size():
            # emit_signal("ime_text_changed", candidates[actual_index])
            handle_candidate_selection(actual_index)
            # reset_ime()
            get_viewport().set_input_as_handled()
            return
    
    # 处理拼音输入
    if key_string.length() == 1 and key_string.is_valid_identifier():
        pinyin_buffer += key_string.to_lower()
        update_candidates()
        get_viewport().set_input_as_handled()

func _get_segment_matches(buffer: String) -> Array:
    var segment_candidates = []
    
    # 只从开始位置尝试匹配，不再遍历所有位置
    var matched_chars = []
    var total_freq = 0.0
    var current_pos = 0
    var matched_length = 0
    
    # 尝试从当前位置开始匹配
    while current_pos < buffer.length():
        var found = false
        for length in range(6, 0, -1):  # 从最长的可能拼音开始尝试
            if current_pos + length > buffer.length():
                continue
                
            var segment = buffer.substr(current_pos, length)
            
            if segment.length() > 0:
                var first_letter = segment[0]
                if first_letter in pinyin_dict_cache:
                    for possible_pinyin in pinyin_dict_cache[first_letter]:
                        if possible_pinyin == segment and segment in pinyin_dict:
                            # 找到最高频率的字符
                            var best_char = ""
                            var best_freq = 0.0
                            for char in pinyin_dict[segment]:
                                if char in char_frequencies and segment in char_frequencies[char]:
                                    var freq = char_frequencies[char][segment]
                                    if freq > best_freq:
                                        best_freq = freq
                                        best_char = char
                            
                            if best_freq > 2000.0:
                                matched_chars.append(best_char)
                                total_freq += best_freq
                                current_pos += length
                                matched_length = current_pos
                                found = true
                                break
                    if found:
                        break
        if not found:
            break  # 如果没有找到匹配，直接退出
    
    # 如果找到了有效的分段匹配
    if matched_chars.size() > 0:
        var combined = "".join(matched_chars)
        var avg_freq = total_freq / matched_chars.size()
        if avg_freq > 2000.0:
            segment_candidates.append({
                "char": combined,
                "freq": avg_freq,
                "matched_length": matched_length
            })
    
    return segment_candidates

func _get_exact_matches(buffer: String) -> Array:
    var exact_candidates = []
    if buffer in pinyin_dict:
        for char in pinyin_dict[buffer]:
            var freq = 0.0
            if char in char_frequencies and buffer in char_frequencies[char]:
                freq = char_frequencies[char][buffer]
            exact_candidates.append({
                "char": char,
                "freq": freq,
                "matched_length": buffer.length()
            })
    return exact_candidates

func _get_prefix_matches(buffer: String) -> Array:
    var prefix_candidates = []
    if buffer.length() > 0:
        var first_letter = buffer[0]
        if first_letter in pinyin_dict_cache:
            for key in pinyin_dict_cache[first_letter]:
                if prefix_candidates.size() >= 10:
                    break
                if key.begins_with(buffer) and key != buffer:
                    for char in pinyin_dict[key]:
                        var freq = 0.0
                        if char in char_frequencies and key in char_frequencies[char]:
                            freq = char_frequencies[char][key]
                        if freq > 1000.0:
                            prefix_candidates.append({
                                "char": char,
                                "freq": freq,
                                "matched_length": buffer.length()
                            })
    return prefix_candidates

func update_candidates() -> void:
    candidates.clear()
    candidates_matched_lengths.clear()
    current_selection = 0
    current_page = 0
    
    var candidates_with_freq = []
    
    # 获取各种匹配结果
    var exact_matches = _get_exact_matches(pinyin_buffer)
    var segment_matches = _get_segment_matches(pinyin_buffer)
    var prefix_matches = _get_prefix_matches(pinyin_buffer)
    
    # 如果有精确匹配，优先添加精确匹配的结果
    if exact_matches.size() > 0:
        # 对精确匹配结果按频率排序
        exact_matches.sort_custom(func(a, b): return a["freq"] > b["freq"])
        candidates_with_freq.append_array(exact_matches)
        
        # 只有在没有足够的精确匹配时才添加其他匹配
        if exact_matches.size() < page_size:
            candidates_with_freq.append_array(segment_matches)
            candidates_with_freq.append_array(prefix_matches)
    else:
        # 没有精确匹配时，添加所有其他匹配
        candidates_with_freq.append_array(segment_matches)
        candidates_with_freq.append_array(prefix_matches)
        # 对所有结果按频率排序
        candidates_with_freq.sort_custom(func(a, b): return a["freq"] > b["freq"])
    
    # 提取排序后的汉字和对应的匹配长度
    for item in candidates_with_freq:
        candidates.append(item["char"])
        candidates_matched_lengths.append(item["matched_length"])

func reset_ime() -> void:
    pinyin_buffer = ""
    candidates.clear()
    current_selection = 0
    current_page = 0

func toggle_ime() -> void:
    is_ime_active = !is_ime_active
    emit_signal('ime_state_changed', is_ime_active)
    if not is_ime_active:
        reset_ime()

func get_current_state() -> Dictionary:
    return {
        "pinyin": pinyin_buffer,
        "candidates": candidates,
        "current_selection": current_selection,
        "is_active": is_ime_active,
        "current_page": current_page,
        "page_size": page_size
    }

func handle_candidate_selection(index: int) -> void:
    if index >= candidates.size() or index >= candidates_matched_lengths.size():
        reset_ime()
        return
        
    var selected_char = candidates[index]
    var matched_length = candidates_matched_lengths[index]
    
    # 如果还有未匹配的拼音，保留在buffer中
    if matched_length < pinyin_buffer.length():
        # 保留未匹配的部分
        var remaining = pinyin_buffer.substr(matched_length)
        
        if remaining.length() > 0:
            emit_signal("ime_text_changed", selected_char)
            var temp_buffer = remaining
            pinyin_buffer = temp_buffer
            update_candidates()  # 更新候选列表
            return
    
    # 如果是完全匹配或没有剩余部分
    emit_signal("ime_text_changed", selected_char)
    reset_ime()
