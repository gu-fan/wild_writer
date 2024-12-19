# scripts/ime/matchers/pinyin_matcher.gd
class_name PinyinMatcher

var trie: PinyinTrie
var fuzzy_rules: Dictionary
var first_letter_cache = {}

func _init():
    trie = PinyinTrie.new()
    _init_fuzzy_rules()

# 加载拼音词典
func load_dictionary(path: String) -> void:
    # Initialize first-letter cache
    for ascii in range(97, 123):
        first_letter_cache[char(ascii)] = {
            "full": [],  # Store complete pinyin
            "prefix": [] # Store common prefixes
        }
    
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        print("Failed to load pinyin dictionary: ", path)
        return
    
    var count = 0
    while !file.eof_reached():
        var line = file.get_line().strip_edges()
        if line.is_empty() or line.begins_with("#"):
            continue
            
        var parts = line.split(" ", false, 3)
        if parts.size() < 4:
            continue
            
        var char = parts[0]
        var freq = parts[1].to_float()
        var pinyin = parts[3].replace(" ", "")
        
        # Add to first-letter cache with more structure
        var first_letter = pinyin[0]
        if first_letter in first_letter_cache:
            first_letter_cache[first_letter].full.append({
                "pinyin": pinyin,
                "freq": freq,
                "char": char
            })
            
            # Cache common prefixes (up to 3 characters)
            for i in range(1, min(4, pinyin.length())):
                var prefix = pinyin.substr(0, i)
                if not prefix in first_letter_cache[first_letter].prefix:
                    first_letter_cache[first_letter].prefix.append(prefix)
        
        # 插入到Trie树
        trie.insert(pinyin, char, freq)
        count += 1
    
    print("Loaded %d entries from dictionary" % count)

# 更新候选词列表
func update_candidates(context: CompositionContext) -> void:
    if context.buffer.is_empty():
        context.candidates.clear()
        context.candidates_matched_lengths.clear()
        return
    
    # 搜索匹配的字符
    var matches = []
    var matched_lengths = []  # 存储每个匹配的长度
    
    # 1. 精确匹配
    var exact_matches = trie.search(context.buffer)
    for match in exact_matches:
        matches.append(match)
        matched_lengths.append(context.buffer.length())
    
    # 2. 前缀匹配 - 进一步优化版本
    if context.buffer.length() > 0:
        var first_letter = context.buffer[0]
        if first_letter in first_letter_cache:
            var cache = first_letter_cache[first_letter]
            var count = 0
            
            # First check if input is a common prefix
            if context.buffer in cache.prefix:
                # Match against full pinyins starting with this prefix
                for entry in cache.full:
                    if count >= 10:
                        break
                    if entry.pinyin.begins_with(context.buffer):
                        var match = {
                            "char": entry.char,
                            "freq": entry.freq * 0.9,  # Lower priority for prefix matches
                            "pinyin": entry.pinyin
                        }
                        if not _contains_char(matches, match.char):
                            matches.append(match)
                            matched_lengths.append(context.buffer.length())  # 只匹配输入的长度
                            count += 1
    
    # 3. 分段匹配 - 优化版本
    var segment_matches = trie.segment_match(context.buffer)
    for segment in segment_matches:
        if segment.matches.size() > 0:
            var best_match = segment.matches[0]
            if not _contains_char(matches, best_match.char):
                # Boost frequency for longer matches
                var length_boost = segment.length / context.buffer.length()
                best_match.freq *= (1.0 + length_boost)
                matches.append(best_match)
                matched_lengths.append(segment.length)  # 使用实际匹配的长度
    
    # 4. 模糊音匹配
    var fuzzy_matches = _get_fuzzy_matches(context.buffer)
    for item in fuzzy_matches:
        if not _contains_char(matches, item.char):
            item.freq *= 0.8
            matches.append(item)
            matched_lengths.append(item.get("matched_length", context.buffer.length()))
    
    # 最终排序：优先考虑匹配长度，然后是频率
    var sorted_indices = range(matches.size())
    sorted_indices.sort_custom(func(a, b): 
        var a_len = matched_lengths[a]
        var b_len = matched_lengths[b]
        
        # 如果长度不同，优先选择更长的匹配
        if a_len != b_len:
            return a_len > b_len
            
        # 长度相同时，按频率排序
        return matches[a].freq > matches[b].freq
    )
    
    # 按排序后的顺序重组数组
    var sorted_matches = []
    var sorted_lengths = []
    for i in sorted_indices:
        sorted_matches.append(matches[i])
        sorted_lengths.append(matched_lengths[i])
    
    # 更新上下文
    context.candidates = sorted_matches.map(func(m): return m.char)
    context.candidates_matched_lengths = sorted_lengths  # 直接使用匹配长度数组
    context.current_selection = 0
    context.current_page = 0

# 辅助函数：检查字符是否已在匹配列表中
func _contains_char(matches: Array, char: String) -> bool:
    return matches.any(func(m): return m.char == char)

# 获取模糊音匹配
func _get_fuzzy_matches(input: String) -> Array:
    var matches = []
    var variants = _generate_fuzzy_variants(input)
    
    for variant in variants:
        var fuzzy_matches = trie.search(variant)
        for item in fuzzy_matches:
            item.freq *= 0.8  # 降低模糊音匹配的权重
            matches.append(item)
    
    return matches

# 生成模糊音变体
func _generate_fuzzy_variants(input: String) -> Array:
    var variants = []
    var syllables = _split_syllables(input)  # 需要实现拼音分割
    
    for i in range(syllables.size()):
        var syllable = syllables[i]
        var initial = _get_initial(syllable)
        var final = _get_final(syllable)
        
        # 处理声母模糊音
        if initial in fuzzy_rules.initials:
            for variant in fuzzy_rules.initials[initial]:
                var new_syllable = variant + final
                var new_input = _replace_syllable(input, syllables, i, new_syllable)
                variants.append(new_input)
        
        # 处理韵母模��音
        if final in fuzzy_rules.finals:
            for variant in fuzzy_rules.finals[final]:
                var new_syllable = initial + variant
                var new_input = _replace_syllable(input, syllables, i, new_syllable)
                variants.append(new_input)
    
    return variants

# 初始化模糊音规则
func _init_fuzzy_rules() -> void:
    fuzzy_rules = {
        "initials": {
            "z": ["zh"],
            "zh": ["z"],
            "c": ["ch"],
            "ch": ["c"],
            "s": ["sh"],
            "sh": ["s"],
            "l": ["n"],
            "n": ["l"],
            "r": ["l"],
            "h": ["f"],
            "f": ["h"]
        },
        "finals": {
            "an": ["ang"],
            "ang": ["an"],
            "en": ["eng"],
            "eng": ["en"],
            "in": ["ing"],
            "ing": ["in"],
            "ian": ["iang"],
            "iang": ["ian"],
            "uan": ["uang"],
            "uang": ["uan"]
        }
    }

# 获取匹配器状态
func get_state() -> Dictionary:
    return {
        "fuzzy_enabled": not fuzzy_rules.is_empty()
    }

# 辅助函数：拼音分割（需要实现）
func _split_syllables(input: String) -> Array:
    # TODO: 实现拼音分割逻辑
    return [input]

# 辅助函数：获取声母
func _get_initial(syllable: String) -> String:
    # 简单实现，需要完善
    for i in ["zh", "ch", "sh"]:
        if syllable.begins_with(i):
            return i
    return syllable[0] if not syllable.is_empty() else ""

# 辅助函数：获取韵母
func _get_final(syllable: String) -> String:
    # 简单实现，需要完善
    var initial = _get_initial(syllable)
    return syllable.substr(initial.length())

# 辅助函数：替换音节
func _replace_syllable(input: String, syllables: Array, index: int, new_syllable: String) -> String:
    var result = syllables.duplicate()
    result[index] = new_syllable
    return "".join(result)
