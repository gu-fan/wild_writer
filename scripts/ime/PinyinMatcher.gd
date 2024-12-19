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
    
    print("\n=== Debug for input:", context.buffer, " ===")
    
    var matches = []
    var matched_lengths = []
    var seen_chars = {}
    
    # 1. 尝试完整匹配（包括多字词组）
    var full_matches = trie.search(context.buffer)
    print("Full matches:", full_matches.map(func(m): return m.char))
    for match in full_matches:
        if not match.char in seen_chars:
            print("  Adding full match:", match.char, "length:", context.buffer.length())
            matches.append(match)
            matched_lengths.append(context.buffer.length())
            seen_chars[match.char] = true
    
    # 2. 尝试前缀的完整匹配
    # 从最长的可能前缀开始尝试
    for length in range(context.buffer.length(), 0, -1):
        var prefix = context.buffer.substr(0, length)
        var prefix_matches = trie.search(prefix)
        print("Prefix matches for %s:" % prefix, prefix_matches.map(func(m): return m.char))
        for match in prefix_matches:
            if not match.char in seen_chars:
                print("  Adding prefix match:", match.char, "length:", prefix.length())
                matches.append(match)
                matched_lengths.append(prefix.length())
                seen_chars[match.char] = true
    
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
    context.candidates_matched_lengths = sorted_lengths
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
        
        # 处理韵母模糊音
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

# 辅助函数：取声母
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
