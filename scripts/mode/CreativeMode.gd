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
var total_style_score := 0
var input_sequence: Array = []        # 记录输入序列
var word_lengths: Array = []          # 词长度统计
var last_input_time: float = 0.0      # 上次输入时间
var repeated_words: int = 0           # 重复词计数
var natural_words: int = 0            # 自然长度的词计数
var paragraph_words: int = 0
var paragraph_stats = {}

var _updated_tick = 0

func _physics_process(delta):
    _updated_tick += delta
    if _updated_tick > 1.0:
        update_stats()
        _updated_tick = 0

# 自然度评估参数
const NATURAL_WORD_LENGTH = {
    "en": {"min": 2, "ideal": 6, "max": 16},    # 英文词长度范围
    "cn": {"min": 1, "ideal": 8, "max": 16}      # 中文词长度范围
}

const STYLE_WEIGHTS = {
    "natural_length": 0.5,    # 自然词长度权重
    "repetition": 0.3,        # 重复度权重
    "rhythm": 0.2             # 节奏权重
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

const zh_seps = [
"",
"省县市镇村乡区",
"",
"｀－＝［］、‘；／。，｜？》《：“｛｝＋—）（＊…％￥＃·！～’”〕〈〉「」『』〖〗【】＜＞",
]

# const en_symbols = [" ", ".", ",", "!", "?", ";", ":", "'", "\"", "`", "\n", "\t", "{", "}", "(", ")", "[", "]", "<", ">", "+", "-", "=", "*", "/"]
const cn_symbols = "　｀－＝［］、‘；／。，｜？》《：“｛｝＋—）（＊…％￥＃·！～’”〕〈〉「」『』〖〗【】＜＞"
const en_symbols = " .,!?;:'\"`\n\t{}()[]<>+-*/=%"
const cn_sep = "给的说对在和是被最所那这有将你会与他为不没很了啊哦呵把去届次集章第每只及于到也又我"
const cn_full_pre_match = '应享给视及因对由关可看听来在也就如一其自这那多少才每或我没中始收也'
const cn_next_match_word = {
        '如': '果',
        '始': '于',
        '收': '到',
        '没': '有',
        '中': '央国共心风产外间',
        '我': '们',
        '或': '者',
        '每': '个人份',
        '才': '是好',
        '多': '少心好肉',
        '少': '女年爷妇',
        '这': '个里些块点种',
        '那': '个里些块点种',
        '一': '些定个点只件条起',
        '就': '是',
        '也': '是在',
        '其': '中一他余',
        '应': '该对',
        '自': '己',
        '享': '有',
        '来': '到',
        '给': '予',
        '视': '为',
        '看': '见到了',
        '及': '其',
        '因': '为此果',
        '在': '于',
        '对': '于',
        '由': '于',
        '关': '于',
        '可': '能以',
        '听': '见说到了',
    }
# const cn_full = ['应对', '应该', '享有', '给予', '视为','及其','因为', '对于', '由于', '关于','可能','因此', '如果', '因果','看见','可以','看到','听说','听见','听到','就是','也在','一些','一定', '其中','自己']

# 更新风格统计
func update_style_stats(paragraph: String) -> void:
    var current_time = Time.get_unix_time_from_system()

    paragraph_stats = {
        words = 1,
    }
    input_sequence = []
    
    # 分割段落为单词
    var words = []
    var current_word = ""


    var i = 0
    while i < paragraph.length():
        var c = paragraph[i]
        # 检查是否是中文字符
        if c.unicode_at(0) > 127:
            if c in cn_symbols:
                if current_word != "":
                    words.append(current_word)
                    current_word = ""
            else:
                # 如果当前有英文单词，先保存
                if current_word != "":
                    if current_word[0].unicode_at(0) > 127:
                        current_word += c
                    else:
                        words.append(current_word)
                        current_word = c
                else:
                    current_word = c
        # 检查分隔符
        elif c in en_symbols:
            if current_word != "":
                words.append(current_word)
                current_word = ""
        else:
            if current_word != "":
                if current_word[0].unicode_at(0) < 127:
                    current_word += c
                else:
                    words.append(current_word)
                    current_word = c
            else:
                current_word = c
        i += 1
    
    # 处理最后一个单词
    if current_word != "":
        words.append(current_word)

    # 进一步处理中文词
    var final_words = []
    for word in words:
        if word.strip_edges() != "":
            if word[0].unicode_at(0) > 127:
                # 对中文词进行分词
                var chinese_words = split_chinese_sentence(word)
                final_words.append_array(chinese_words)
            else:
                final_words.append(word)

    # 分析每个词
    for word in final_words:
        if word.strip_edges() != "":
            _analyze_word(word, current_time)
    
    print('got words', final_words, paragraph_stats)
    last_input_time = current_time

    paragraph_stats.words = final_words


    _calculate_style_rating()

# 分析单词
func _analyze_word(word: String, time: float) -> void:
    paragraph_words += 1
    paragraph_stats.words = paragraph_words

    if input_sequence.has(word):
        repeated_words += 1
    input_sequence.append(word)
    
    # 保持最近50个词的记录
    if input_sequence.size() > 50:
        input_sequence.pop_front()
    
    
    var word_length = word.length()
    # var word_length = _get_word_length(word)
    word_lengths.append(word_length)
    paragraph_stats.word_lengths = word_lengths

    # 检查是否是自然长度
    if _is_natural_word(word):
        natural_words += 1

    paragraph_stats.natural_words = natural_words


# 获取词长度（考虑中英文混合）
func _get_word_length(word: String) -> int:
    var length = 0
    for c in word:
        # 中文字符计数为2，英文字符计数为1
        length += 2 if c.unicode_at(0) > 127 else 1
    return length

# 检查是否是自然长度和字符重复
func _is_natural_word(word: String) -> bool:
    var is_chinese = word.unicode_at(0) > 127
    var length = word.length()
    var params = NATURAL_WORD_LENGTH.cn if is_chinese else NATURAL_WORD_LENGTH.en
    if length < params.min:
        prints('unnatural word:', word, 'length less than min')
        return false
    elif length > params.max: 
        # if is_chinese:
        #     var words = split_chinese_sentence(word)
        #     # split word with cn_seps, and check the length
        #     var max_size = get_max_size_of_words(words)
        #     if max_size > params.max:
        #         prints('unnatural word:', word, 'length more than max')
        #         return false
        # else:
        prints('unnatural word:', word, 'length more than max')
        return false

    # 检查字符重复
    if _has_excessive_repeats(word): return false

    return true

# 检查是否有过多重复字符
func _has_excessive_repeats(word: String) -> bool:
    var char_counts = {}
    var consecutive_count = 1
    var last_char = ''
    
    for i in range(word.length()):
        var c = word[i]
        
        # 检查总体重复次数
        if not char_counts.has(c):
            char_counts[c] = 0
        char_counts[c] += 1
        
        # 检查连续重复
        if c == last_char:
            consecutive_count += 1
            # 如果有连续三个相同字母
            if consecutive_count >= 3:
                prints('unnatural word:', word, 'consecutive repeat char:', c)
                return true
        else:
            consecutive_count = 1
        
        # 如果任何字符总重复超过4次
        if char_counts[c] > 4:
            prints('unnatural word:', word, 'total repeat char:', c)
            return true
            
        last_char = c
    
    return false


# 计算风格评分
func _calculate_style_rating() -> void:
    if paragraph_words == 0:
        style_rating = "NA"
        return
    
    # 计算自然长度得分
    var natural_ratio = float(natural_words) / paragraph_words
    prints('unnatural', (paragraph_words - natural_words), natural_ratio)
    
    # 计算重复度得分（越低越好）
    var repetition_ratio = 1.0 - (float(repeated_words) / paragraph_words)
    prints('repeat', repeated_words, paragraph_words, repetition_ratio)
    
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
        "A": 90.0,  # 85-95：非常好的输入
        "B": 80.0,  # 75-85：良好的输入
        "C": 65.0,  # 65-75：一般的输入
        "D": 0.0    # <65：需要改进
    })
    prints('style:', natural_ratio, repetition_ratio, rhythm_score, final_score, style_rating)

# 计算节奏得分
func _calculate_rhythm_score() -> float:
    if word_lengths.size() < 4:  # 至少需要4个词才能评估节奏
        return 1.0
    
    # 使用滑动窗口检查连续4个词的长度
    var rhythm_issues = 0
    var total_windows = 0
    var words = paragraph_stats.words
    
    for i in range(word_lengths.size() - 3):  # -3确保有4个词的窗口
        var window = []
        var window_words = []
        var window_sum = 0
        
        # 获取连续4个词的长度和词
        for j in range(4):
            window.append(word_lengths[i + j])
            window_words.append(words[i + j])
            window_sum += word_lengths[i + j]
        
        total_windows += 1
        
        # 检查节奏问题
        var has_rhythm_issue = false
        var issue_reason = ""
        
        # 检查窗口中的词是否都是中文或英文
        var all_chinese = true
        var all_english = true
        for word in window_words:
            var is_chinese_word = word[0].unicode_at(0) > 127
            all_chinese = all_chinese and is_chinese_word
            all_english = all_english and not is_chinese_word
        
        # 只有当所有词都是同一类型时才应用相应规则
        if all_chinese:
            # 中文词长度规则
            var all_short = true
            for length in window:
                if length > 1:  # 中文词超过1个字
                    all_short = false
                    break
            if all_short:
                has_rhythm_issue = true
                issue_reason = "all short chinese words"
            
            var all_long = true
            for length in window:
                if length < 8:  # 中文词少于8个字
                    all_long = false
                    break
            if all_long:
                has_rhythm_issue = true
                issue_reason = "all long chinese words"
        elif all_english:
            # 英文词长度规则
            var all_short = true
            for length in window:
                if length >= 4:
                    all_short = false
                    break
            if all_short:
                has_rhythm_issue = true
                issue_reason = "all short english words"
            
            var all_long = true
            for length in window:
                if length <= 20:
                    all_long = false
                    break
            if all_long:
                has_rhythm_issue = true
                issue_reason = "all long english words"
        
        # 计算平均长度
        var avg_length = float(window_sum) / 4
        
        # 检查变化是否太小（节奏单调）
        var variation = 0
        for length in window:
            variation += abs(length - avg_length)
        if variation < 1:  # 如果4个词长度几乎相同
            has_rhythm_issue = true
            issue_reason = "monotonous rhythm"
        
        if has_rhythm_issue:
            rhythm_issues += 1
            prints('rhythm issue:', issue_reason)
            prints('lengths:', window)
            prints('words:', window_words)
    
    # 计算最终得分
    var rhythm_score = 1.0
    if total_windows > 0:
        rhythm_score = 1.0 - (float(rhythm_issues) / total_windows)
    
    prints('rhythm score:', rhythm_score, 'issues:', rhythm_issues, 'windows:', total_windows)
    return rhythm_score

# -------------------------------
# split chinese word
func split_chinese_sentence(sentence):
    var words = []
    var current_word = ""

    var current_match_word = ""  # '应'
    var next_match_words = ''     # ['对', '该']
    var current_match_index = -2

    var i = 0
    while i < sentence.length():
        var c = sentence[i]
        if i == current_match_index + 1: # this will lost the char that at end of cn_words
            if c in next_match_words:
                current_match_word += c
                if current_word != "":
                    words.append(current_word)
                    current_word = ""
                words.append(current_match_word)
            else:
                # fallback to use cn_sep to split words
                # "但考虑到之前一些媒体对胖东来干预员工个人生活的批评"
                # -> 
                # "但考虑到之前一些媒体", "对","胖东来干预员工个人生活的批评"
                if c in cn_full_pre_match:
                    current_word += current_match_word
                    words.append(current_word)
                    current_word = ""
                    current_match_word = c
                    current_match_index = i
                    next_match_words = cn_next_match_word[c]
                elif c in cn_sep:
                    current_word += current_match_word
                    words.append(current_word)
                    words.append(c)
                    current_word = ""
                elif current_match_word in cn_sep:
                    if current_word != "":
                        words.append(current_word)
                    words.append(current_match_word)
                    current_word = c
                else:
                    current_word += current_match_word
                    current_word += c
        elif c in cn_full_pre_match:
            # check if c in cn_full_pre_match
            # if is in, then 
            current_match_word = c
            current_match_index = i
            next_match_words = cn_next_match_word[c]
        elif c in cn_sep:
            if current_word != "":
                words.append(current_word)
                current_word = ""
            words.append(c)
        else:
            current_word += c

        i += 1

    if current_word != "":
        words.append(current_word)
    return words
func get_max_size_of_words(words):
    var max_size = 0
    for w in words:
        if w.length() > max_size:
            max_size = w.length()
    return max_size
