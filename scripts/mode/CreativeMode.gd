class_name CreativeMode
extends Node

signal goal_reached
signal stats_updated

# 目标和进度
var typing_goal: int = 1000  # 默认目标
var current_chars: int = 0   # 当前输入字符数

# 速度统计
var start_time: float = 0.0
var wpm: float = 0.0        # 每分钟字数
var kpm: float = 0.0        # 每分钟按键数
var total_keys: int = 0
var total_words: int = 0

# 准确度统计
var total_chars: int = 0
var correct_chars: int = 0
var wrong_chars: int = 0
var accuracy: float = 100.0

# 评分系统
var speed_rating: String = "S"
var style_rating: String = "A"
var accuracy_rating: String = "S"

# 风格统计相关变量
var input_sequence: Array = []        # 记录输入序列
var word_lengths: Array = []          # 词长度统计
var last_input_time: float = 0.0      # 上次输入时间
var repeated_words: int = 0           # 重复词计数
var natural_words: int = 0            # 自然长度的词计数

var _updated_tick = 0

# 自然度评估参数
const NATURAL_WORD_LENGTH = {
    "en": {"min": 3, "ideal": 5, "max": 12},    # 英文词长度范围
    "cn": {"min": 2, "ideal": 3, "max": 6}      # 中文词长度范围
}

const STYLE_WEIGHTS = {
    "natural_length": 0.4,    # 自然词长度权重
    "repetition": 0.3,        # 重复度权重
    "rhythm": 0.3             # 节奏权重
}

func _ready() -> void:
    start_time = Time.get_unix_time_from_system()

func set_goal(chars: int) -> void:
    typing_goal = chars
    current_chars = 0
    _reset_stats()

func _reset_stats() -> void:
    start_time = Time.get_unix_time_from_system()
    wpm = 0.0
    kpm = 0.0
    total_keys = 0
    total_words = 0
    correct_chars = 0
    wrong_chars = 0
    accuracy = 100.0

func incr_word(n=1):
    total_words += n
    update_stats()
func incr_error():
    wrong_chars += 1
    total_chars -= 1
    update_stats()
func incr_key(count = 1):
    total_keys += count
    total_chars += 1
    update_stats()
    

func update_stats() -> void:
    # total_keys += 1
    
    # if is_correct:
    #     correct_chars += char_count
    # else:
    #     wrong_chars += char_count
    
    # 更新速度统计
    var elapsed_minutes = (Time.get_unix_time_from_system() - start_time) / 60.0
    if elapsed_minutes > 0:
        wpm = total_words / elapsed_minutes
        kpm = total_keys / elapsed_minutes
    
    # 更新准确度
    # var total_chars = correct_chars + wrong_chars
    if total_chars > 0:
        correct_chars = total_chars - wrong_chars
        accuracy = (correct_chars / float(total_chars)) * 100.0
    
    # 检查是否达到目标
    if current_chars >= typing_goal:
        _calculate_final_rating()
        goal_reached.emit()
    
    stats_updated.emit()

func _calculate_final_rating() -> void:
    # 速度评分 (WPM)
    speed_rating = match_rating(wpm, {
        "S": 120.0,  # 120+ WPM
        "A": 90.0,   # 90-120 WPM
        "B": 60.0,   # 60-90 WPM
        "C": 40.0,   # 40-60 WPM
        "D": 0.0     # <40 WPM
    })
    
    # 准确度评分
    accuracy_rating = match_rating(accuracy, {
        "S": 98.0,   # 98%+
        "A": 95.0,   # 95-98%
        "B": 90.0,   # 90-95%
        "C": 85.0,   # 85-90%
        "D": 0.0     # <85%
    })
    
    # 风格评分 (基于组合和特效使用)
    # 这部分需要根据具体的组合系统来实现
    style_rating = "A"  # 临时默认值

func match_rating(value: float, thresholds: Dictionary) -> String:
    for rating in thresholds:
        if value >= thresholds[rating]:
            return rating
    return "D"

func get_stats() -> Dictionary:
    return {
        "wpm": wpm,
        "kpm": kpm,
        "accuracy": accuracy,
        "progress": float(current_chars) / typing_goal,
        "speed_rating": speed_rating,
        "style_rating": style_rating,
        "accuracy_rating": accuracy_rating
    }

# 更新风格统计
func update_style_stats(text: String, is_word_complete: bool = false) -> void:
    var current_time = Time.get_unix_time_from_system()
    
    # 检查是否是新词
    if is_word_complete:
        var word = text.strip_edges()
        if word.length() > 0:
            _analyze_word(word, current_time)
    
    last_input_time = current_time
    _calculate_style_rating()

# 分析单词
func _analyze_word(word: String, time: float) -> void:
    total_words += 1
    
    # 检查是否是重复词
    if input_sequence.has(word):
        repeated_words += 1
    input_sequence.append(word)
    
    # 保持最近50个词的记录
    if input_sequence.size() > 50:
        input_sequence.pop_front()
    
    # 分析词长度
    var word_length = _get_word_length(word)
    word_lengths.append(word_length)
    if word_lengths.size() > 50:
        word_lengths.pop_front()
    
    # 检查是否是自然长度
    if _is_natural_length(word):
        natural_words += 1

# 获取词长度（考虑中英文混合）
func _get_word_length(word: String) -> int:
    var length = 0
    for c in word:
        # 中文字符计数为2，英文字符计数为1
        length += 2 if c.unicode_at(0) > 127 else 1
    return length

# 检查是否是自然长度
func _is_natural_length(word: String) -> bool:
    var length = _get_word_length(word)
    var is_chinese = _is_mainly_chinese(word)
    var params = NATURAL_WORD_LENGTH.cn if is_chinese else NATURAL_WORD_LENGTH.en
    
    return length >= params.min and length <= params.max

# 判断是否主要是中文
func _is_mainly_chinese(word: String) -> bool:
    var cn_count = 0
    for c in word:
        if c.unicode_at(0) > 127:
            cn_count += 1
    return cn_count > word.length() / 2

# 计算风格评分
func _calculate_style_rating() -> void:
    if total_words == 0:
        style_rating = "S"
        return
    
    # 计算自然长度得分
    var natural_ratio = float(natural_words) / total_words
    
    # 计算重复度得分（越低越好）
    var repetition_ratio = 1.0 - (float(repeated_words) / total_words)
    
    # 计算节奏得分
    var rhythm_score = _calculate_rhythm_score()
    
    # 综合评分
    var final_score = (
        natural_ratio * STYLE_WEIGHTS.natural_length +
        repetition_ratio * STYLE_WEIGHTS.repetition +
        rhythm_score * STYLE_WEIGHTS.rhythm
    ) * 100.0
    
    # 设置评级
    style_rating = match_rating(final_score, {
        "S": 95.0,  # 95+：极其自然的输入
        "A": 85.0,  # 85-95：非常好的输入
        "B": 75.0,  # 75-85：良好的输入
        "C": 65.0,  # 65-75：一般的输入
        "D": 0.0    # <65：需要改进
    })

# 计算节奏得分
func _calculate_rhythm_score() -> float:
    if word_lengths.size() < 2:
        return 1.0
    
    # 分析词长度的变化
    var variations = []
    for i in range(1, word_lengths.size()):
        variations.append(abs(word_lengths[i] - word_lengths[i-1]))
    
    # 计算变化的平均值和标准差
    var avg_variation = 0.0
    for v in variations:
        avg_variation += v
    avg_variation /= variations.size()
    
    # 将平均变化转换为0-1的分数（变化越自然，分数越高）
    return 1.0 / (1.0 + avg_variation * 0.2)

func _physics_process(delta):
    _updated_tick += delta
    if _updated_tick > 1.0:
        update_stats()
        _updated_tick = 0
