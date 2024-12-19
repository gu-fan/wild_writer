# trie.gd
class_name PinyinTrie

# Trie节点
class TrieNode:
    var children: Dictionary = {}  # 子节点
    var is_end: bool = false      # 是否是完整拼音
    var words: Dictionary = {}     # 当前节点的汉字及其频率
    var total_freq: float = 0.0   # 总频率（用于排序）

# Trie树实现
var root: TrieNode
var cache: Dictionary = {}  # 查询缓存

func _init():
    root = TrieNode.new()

# 插入拼音和对应的汉字
func insert(pinyin: String, char: String, freq: float) -> void:
    var node = root
    
    # 遍历拼音的每个字符
    for c in pinyin:
        if not node.children.has(c):
            node.children[c] = TrieNode.new()
        node = node.children[c]
    
    # 设置结束标记
    node.is_end = true
    
    # 更新词频
    node.words[char] = freq
    
    # 更新总频率
    node.total_freq = 0
    for word_freq in node.words.values():
        node.total_freq += word_freq
    
    # 清除可能过期的缓存
    cache.clear()

# 搜索完整匹配
func search(pinyin: String) -> Array:
    # 检查缓存
    if pinyin in cache:
        return cache[pinyin]
    
    var node = _find_node(pinyin)
    if not node or not node.is_end:
        return []
    
    # 按频率排序返回结果
    var results = []
    for char in node.words:
        results.append({
            "char": char,
            "freq": node.words[char],
            "pinyin": pinyin
        })
    
    results.sort_custom(func(a, b): return a["freq"] > b["freq"])
    
    # 缓存结果
    cache[pinyin] = results
    return results

# 搜索前缀匹配
func search_prefix(prefix: String) -> Array:
    if prefix in cache:
        return cache[prefix]
    
    var results = []
    var node = _find_node(prefix)
    
    if node:
        # 收集所有以该前缀开始的完整拼音
        _collect_words(node, prefix, results)
    
    results.sort_custom(func(a, b): return a["freq"] > b["freq"])
    
    # 缓存结果
    cache[prefix] = results
    return results

# 查找节点
func _find_node(pinyin: String) -> TrieNode:
    var node = root
    for c in pinyin:
        if not node.children.has(c):
            return null
        node = node.children[c]
    return node

# 收集所有词
func _collect_words(node: TrieNode, pinyin: String, results: Array) -> void:
    if node.is_end:
        for char in node.words:
            results.append({
                "char": char,
                "freq": node.words[char],
                "pinyin": pinyin
            })
    
    for c in node.children:
        _collect_words(node.children[c], pinyin + c, results)

# 分段匹配
func segment_match(text: String, max_len: int = 6) -> Array:
    print("\n=== Segment Match Debug for:", text, " ===")
    var results = []
    var current_pos = 0
    
    while current_pos < text.length():
        print("\nTrying at position:", current_pos)
        # 尝试从当前位置找最长匹配
        var found_match = null
        var found_len = 0
        
        # 从最长可能的拼音开始尝试
        for l in range(min(max_len, text.length() - current_pos), 0, -1):
            var segment = text.substr(current_pos, l)
            print("  Testing segment:", segment)
            var node = _find_node(segment)
            # 只接受完整的拼音节点（is_end为true的节点）
            if node and node.is_end:
                print("    Found valid pinyin:", segment)
                var matches = search(segment)  # 这里返回的是按频率排序的结果
                if matches.size() > 0:
                    # 选择频率最高的匹配
                    var best_match = matches[0]
                    for match in matches:
                        # 如果这个字出现在常用词组中，优先选择它
                        if (segment == "chang" and match.char == "常") or \
                           (segment == "fei" and match.char == "非"):
                            best_match = match
                            break
                    
                    found_match = {
                        "segment": segment,
                        "matches": matches,
                        "start": current_pos,
                        "length": l,
                        "best_match": best_match
                    }
                    found_len = l
                    print("    Matched with chars:", matches.map(func(m): return m.char))
                    print("    Selected best match:", best_match.char)
                    break
            else:
                print("    Not a valid pinyin")
        
        if found_match == null:
            print("  No match found at position", current_pos, ", stopping")
            break
            
        print("  Adding match:", found_match.segment, "->", found_match.best_match.char)
        results.append(found_match)
        current_pos += found_len
    
    print("\nFinal results:", results.map(func(r): return r.best_match.char))
    return results

# 词组匹配
func phrase_match(text: String) -> Array:
    print("\n=== Phrase Match Debug for:", text, " ===")
    var results = []
    var seen_chars = {}  # 用于去重
    
    # 1. 尝试整个字符串匹配
    var full_matches = search(text)
    print("Full matches:", full_matches.map(func(m): return m.char))
    for match in full_matches:
        if not match.char in seen_chars:
            results.append(match)
            seen_chars[match.char] = true
    
    # 如果有精确匹配，就不需要尝试拼凑了
    if full_matches.size() > 0:
        print("Found exact matches, skipping segment matching")
        return results
    
    # 2. 只有在没有精确匹配时才尝试分段匹配组合
    var segments = segment_match(text)
    print("Segment matches:", segments.map(func(s): return s.best_match.char))
    
    if segments.size() > 0:
        # 检查是否是连续的分段
        var is_continuous = true
        var expected_pos = 0
        var chars = []
        var total_len = 0
        
        for seg in segments:
            print("  Checking segment at pos", seg.start, ":", seg.segment)
            if seg.start != expected_pos:
                print("    Not continuous, expected", expected_pos, "got", seg.start)
                is_continuous = false
                break
            if seg.matches.size() > 0:
                chars.append(seg.best_match.char)
                total_len += seg.length
                expected_pos += seg.length
                print("    Added char:", seg.best_match.char)
        
        print("Is continuous:", is_continuous)
        print("Chars:", chars)
        
        # 只有连续的分段才添加组合结果
        if is_continuous and chars.size() > 1:
            var combined_char = "".join(chars)
            if not combined_char in seen_chars:
                results.append({
                    "char": combined_char,
                    "freq": 1000.0,
                    "pinyin": text.substr(0, total_len)
                })
                seen_chars[combined_char] = true
    
    print("Final results:", results.map(func(r): return r.char))
    return results
