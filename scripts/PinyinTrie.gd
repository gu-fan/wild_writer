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
    var results = []
    var i = 0
    
    while i < text.length():
        var matched = false
        # 从最长的可能拼音开始尝试
        for l in range(min(max_len, text.length() - i), 0, -1):
            var segment = text.substr(i, l)
            var matches = search(segment)
            if matches.size() > 0:
                results.append({
                    "segment": segment,
                    "matches": matches,
                    "start": i,
                    "length": l
                })
                i += l
                matched = true
                break
        # 如果没有匹配，移动到下一个字符
        if not matched:
            i += 1
    
    return results