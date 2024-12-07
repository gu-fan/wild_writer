extends Node

signal ime_text_changed(text: String)
signal ime_state_changed(v)

var pinyin_buffer: String = ""
var candidates: Array = []
var current_selection: int = 0
var is_ime_active: bool = false

# 简单的拼音到汉字的映射字典
var pinyin_dict = {}

# 修改频率字典的结构，使用 {char: {pinyin: freq}} 的形式
var char_frequencies: Dictionary = {}

var page_size: int = 5
var current_page: int = 0

func _ready():
    load_pinyin_dict()

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

func _input(event: InputEvent) -> void:
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
                    emit_signal("ime_text_changed", candidates[0])
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
            get_viewport().set_input_as_handled()
            if current_page > 0:
                current_page -= 1
                return
        "BracketRight":  # > 键，下一页
            get_viewport().set_input_as_handled()
            if (current_page + 1) * page_size < candidates.size():
                current_page += 1
                return
    
    # Handle number keys for selection (1-5)
    if candidates.size() > 0 and key_string.is_valid_int():
        var num = key_string.to_int() - 1  # Convert to 0-based index
        var actual_index = current_page * page_size + num
        if num >= 0 and num < page_size and actual_index < candidates.size():
            emit_signal("ime_text_changed", candidates[actual_index])
            reset_ime()
            get_viewport().set_input_as_handled()
            return
    
    # 处理拼音输入
    if key_string.length() == 1 and key_string.is_valid_identifier():
        pinyin_buffer += key_string.to_lower()
        update_candidates()
        get_viewport().set_input_as_handled()

func update_candidates() -> void:
    candidates.clear()
    current_selection = 0
    current_page = 0
    
    var candidates_with_freq = []
    var _prefix_candidates = []
    
    # 精确匹配
    if pinyin_buffer in pinyin_dict:
        for char in pinyin_dict[pinyin_buffer]:
            var freq = 0.0
            if char in char_frequencies and pinyin_buffer in char_frequencies[char]:
                freq = char_frequencies[char][pinyin_buffer]
            candidates_with_freq.append({
                "char": char,
                "freq": freq
            })
    
    candidates_with_freq.sort_custom(func(a, b): return a["freq"] > b["freq"])

    # 分段匹配
    var buffer = pinyin_buffer
    var pos = 0
    var matched_chars = []
    var total_freq = 0.0
    
    while pos < buffer.length():
        var found = false
        # 从最长可能的拼音开始尝试
        for length in range(7, 0, -1):  # 假设最长拼音为7个字母
            if pos + length > buffer.length():
                continue
            var segment = buffer.substr(pos, length)
            if segment in pinyin_dict:
                var char = pinyin_dict[segment][0]  # 取频率最高的字
                var freq = 0.0
                if char in char_frequencies and segment in char_frequencies[char]:
                    freq = char_frequencies[char][segment]
                    
                # 只有频率足够高的字才加入组合
                if freq > 1000.0:
                    matched_chars.append(char)
                    total_freq += freq
                    pos += length
                    found = true
                    break
        if not found:
            pos += 1
    
    # 如果找到了完整的分段匹配，且总频率足够高，添加到候选列表
    if matched_chars.size() > 0:
        var combined = "".join(matched_chars)
        var avg_freq = total_freq / matched_chars.size()
        if avg_freq > 1000.0:
            _prefix_candidates.append({
                "char": combined,
                "freq": avg_freq  # 使用平均频率作为组合词的频率
            })
    
    # 前缀匹配
    for key in pinyin_dict:
        if _prefix_candidates.size() >= 10:
            break
        if key.begins_with(pinyin_buffer) and key != pinyin_buffer:
            for char in pinyin_dict[key]:
                var freq = 0.0
                if char in char_frequencies and key in char_frequencies[char]:
                    freq = char_frequencies[char][key]
                if freq > 1000.0:  # 同样只保留高频词
                    _prefix_candidates.append({
                        "char": char,
                        "freq": freq
                    })
    
    # 按频率排序（从高到低）
    _prefix_candidates.sort_custom(func(a, b): return a["freq"] > b["freq"])
    
    candidates_with_freq = candidates_with_freq + _prefix_candidates

    # 提取排序后的汉字
    candidates = candidates_with_freq.map(func(item): return item["char"])

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
