class_name TrieBenchmark

var trie: PinyinTrie
var dict_simple: Dictionary
var test_data: Array
var results: Dictionary

func _init():
    trie = PinyinTrie.new()
    dict_simple = {}
    _load_test_data()

# 加载测试数据
func _load_test_data():
    var file = FileAccess.open("res://scripts/google_pinyin.txt", FileAccess.READ)
    if not file:
        print("Failed to load pinyin dictionary")
        return
    
    test_data = []
    var count = 0
    
    while !file.eof_reached() and count < 10000:  # 限制加载数量，避免内存过大
        var line = file.get_line().strip_edges()
        if line.is_empty() or line.begins_with("#"):
            continue
            
        var parts = line.split(" ", false, 3)
        if parts.size() < 4:
            continue
            
        var char = parts[0]
        var freq = parts[1].to_float()
        var pinyin = parts[3].replace(" ", "")
        
        test_data.append({
            "char": char,
            "pinyin": pinyin,
            "freq": freq
        })
        count += 1

# 执行基准测试
func run_benchmark() -> Dictionary:
    results = {
        "data_size": test_data.size(),
        "insertion": {
            "trie": 0.0,
            "dict": 0.0
        },
        "exact_search": {
            "trie": 0.0,
            "dict": 0.0
        },
        "prefix_search": {
            "trie": 0.0,
            "dict": 0.0
        },
        "memory": {
            "trie": 0,
            "dict": 0
        }
    }
    
    print("Starting benchmark with %d entries..." % test_data.size())
    
    _benchmark_insertion()
    _benchmark_search()
    _benchmark_prefix_search()
    _benchmark_memory()
    
    return results

# 测试插入性能
func _benchmark_insertion():
    var start_time = Time.get_ticks_usec()
    
    # Trie插入测试
    for item in test_data:
        trie.insert(item.pinyin, item.char, item.freq)
    
    results.insertion.trie = (Time.get_ticks_usec() - start_time) / 1000.0
    
    # 字典插入测试
    start_time = Time.get_ticks_usec()
    
    for item in test_data:
        if not dict_simple.has(item.pinyin):
            dict_simple[item.pinyin] = []
        dict_simple[item.pinyin].append({
            "char": item.char,
            "freq": item.freq
        })
    
    results.insertion.dict = (Time.get_ticks_usec() - start_time) / 1000.0

# 测试查找性能
func _benchmark_search():
    var search_samples = _get_random_samples(test_data, 1000)  # 随机取1000个样本测试
    
    var start_time = Time.get_ticks_usec()
    
    # Trie查找测试
    for item in search_samples:
        var a = trie.search(item.pinyin)
    
    results.exact_search.trie = (Time.get_ticks_usec() - start_time) / 1000.0
    
    # 字典查找测试
    start_time = Time.get_ticks_usec()
    
    for item in search_samples:
        var a = dict_simple.get(item.pinyin, [])
    
    results.exact_search.dict = (Time.get_ticks_usec() - start_time) / 1000.0

# 测试前缀查找性能
func _benchmark_prefix_search():
    var prefix_samples = []
    for item in _get_random_samples(test_data, 100):  # 随机取100个样本测试
        prefix_samples.append(item.pinyin.substr(0, min(2, item.pinyin.length())))
    
    var start_time = Time.get_ticks_usec()
    
    # Trie前缀查找测试
    for prefix in prefix_samples:
        var a = trie.search_prefix(prefix)
    
    results.prefix_search.trie = (Time.get_ticks_usec() - start_time) / 1000.0
    
    # 字典前缀查找测试
    start_time = Time.get_ticks_usec()
    
    for prefix in prefix_samples:
        var matches = []
        for key in dict_simple:
            if key.begins_with(prefix):
                matches.append_array(dict_simple[key])
    
    results.prefix_search.dict = (Time.get_ticks_usec() - start_time) / 1000.0

# 测试内存使用
func _benchmark_memory() -> void:
    results.memory.trie = _estimate_trie_size(trie.root)
    results.memory.dict = str(dict_simple).length()

# 辅助函数：随机采样
func _get_random_samples(data: Array, sample_size: int) -> Array:
    var samples = []
    var indices = range(data.size())
    indices.shuffle()
    
    for i in range(min(sample_size, data.size())):
        samples.append(data[indices[i]])
    
    return samples

# 估算Trie树大小
func _estimate_trie_size(node: PinyinTrie.TrieNode) -> int:
    var size = 0
    size += 8  # bool
    size += 24  # Dictionary overhead
    size += 8 * node.children.size()  # Dictionary entries
    size += 16  # words Dictionary
    size += 8 * node.words.size()  # words entries
    
    for child in node.children.values():
        size += _estimate_trie_size(child)
    
    return size

# 生成详细报告
func generate_report() -> String:
    var report = []
    report.append("Trie树性能测试报告 (数据规模: %d)" % results.data_size)
    report.append("================")
    
    report.append("\n插入性能:")
    report.append("Trie: %.2f ms (%.2f µs/项)" % [
        results.insertion.trie,
        results.insertion.trie * 1000 / results.data_size
    ])
    report.append("Dict: %.2f ms (%.2f µs/项)" % [
        results.insertion.dict,
        results.insertion.dict * 1000 / results.data_size
    ])
    
    report.append("\n精确查找性能:")
    report.append("Trie: %.2f ms" % results.exact_search.trie)
    report.append("Dict: %.2f ms" % results.exact_search.dict)
    
    report.append("\n前缀查找性能:")
    report.append("Trie: %.2f ms" % results.prefix_search.trie)
    report.append("Dict: %.2f ms" % results.prefix_search.dict)
    
    report.append("\n估计内存使用:")
    report.append("Trie: %.2f KB" % (results.memory.trie / 1024.0))
    report.append("Dict: %.2f KB" % (results.memory.dict / 1024.0))
    
    return "\n".join(report)
