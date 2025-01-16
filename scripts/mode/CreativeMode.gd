class_name CreativeMode
extends Node

signal goal_new
signal goal_reached
signal goal_finished
signal stats_updated(is_tick:bool)
signal combo_updated

# 目标和进度
var typing_goal: int = 10  # 默认目标
# var has_reached_goal = false
var has_reached_goal = true

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
var max_combo : int = 0

# 评分系统
var speed_rating: String = "NA"
var style_rating: String = "NA"
var accuracy_rating: String = "NA"
var final_rating: String = "NA"
var final_style_scores = {
        "natural": 0.0,
        "repeat": 0.0,
        "punc": 0.0,
        "rhythm": 0.0
    }

const SPEED_SCORE_S = {
    "S": 120.0,
    "A": 90.0,
    "B": 60.0,
    "C": 40.0,
    "D": 0.0
}
const ACCURACY_SCORE_S = {
    "S": 95.0,
    "A": 90.0,
    "B": 85.0,
    "C": 80.0,
    "D": 0.0  
}
const STYLE_SCORE_S = {
    "S": 95.0,
    "A": 90.0,
    "B": 80.0,
    "C": 60.0,
    "D": 0.0   
}
const SPEED_SCORE = {
    "SS": 140.0,
    "S": 120.0,
    "A": 90.0,
    "B": 60.0,
    "C": 40.0,
    "D": 0.0
}
const ACCURACY_SCORE = {
    "SS": 100.0,
    "S": 95.0,
    "A": 90.0,
    "B": 85.0,
    "C": 80.0,
    "D": 0.0  
}
const STYLE_SCORE = {
    "SS": 99.0,
    "S": 95.0,
    "A": 90.0,
    "B": 80.0,
    "C": 60.0,
    "D": 0.0   
}
const FINAL_SCORE_S = {
    "S": 95.0,
    "A": 90.0,
    "B": 80.0,
    "C": 60.0,
    "D": 0.0   
}
const FINAL_SCORE = {
    "SS": 98.0,
    "S": 95.0,
    "A": 90.0,
    "B": 80.0,
    "C": 60.0,
    "D": 0.0   
}

# 风格统计相关变量
var total_style_score := 0

var _updated_tick = 0

# 自然度评估参数
const NATURAL_WORD_LENGTH = {
    "en": {"min": 1, "ideal": 6, "max": 16},    # 英文词长度范围
    "cn": {"min": 1, "ideal": 8, "max": 16}      # 中文词长度范围
}

const STYLE_WEIGHTS = {
    "natural_length": 0.4,     # 自然词长度权重
    "repetition": 0.3,         # 重复度权重
    "punctuation": 0.15,       # 标点
    "rhythm": 0.15             # 节奏权重
}

var paragraph_stats = {
    "words": [],         # Array[String]
    "word_lengths": [],  # Array[int]
    "puncs": [],         # Array[int]
    "length": 0,         # int
    "natural_words": 0,  # int
    "repeated_words": 0, # int
    "total_words": 0,    # int
    # ---------
    "start_time": 0.0,   # float
    "end_time": 0.0,     # float
    "duration": 0.0,          
    "input_words": 0,    # int
    "keys": 0,           # int
    "errors": 0,         # int
    "chars": 0,          # int
    "wpm": 0.0,          # float
    "kpm": 0.0,          # float
    "accuracy": 100.0,    # float
    # ---------
    "score_style": 0,
    "rating_style": "NA",
    "rating_speed": "NA",
    "rating_accuracy": "NA",
}

var creative_mode_stats = {
    "start_time": 0.0,   # float
    "end_time": 0.0,     # float
    "total_paragraphs": 0,    # int
}
var paragraph_scores = []
var _paragraph_input_sequence: Array = []        # 记录输入序列

# -----------------------
func _physics_process(delta):
    if !is_active: return
    _updated_tick += delta
    if _updated_tick > 1.0:
        update_stats(true)
        _updated_tick = 0

# -----------------------
var is_active = false

func _ready() -> void:
    start_time = Time.get_unix_time_from_system()
    _gen_cn_maps()


func _reset_stats() -> void:
    start_time = Time.get_unix_time_from_system()
    wpm = 0.0
    kpm = 0.0
    total_keys = 0
    total_words = 0
    correct_chars = 0
    wrong_chars = 0
    accuracy = 100.0
    max_combo = 0
    speed_rating = "NA"
    style_rating = "NA"
    accuracy_rating = "NA"
    final_rating = "NA"
    final_style_scores = {
        "natural": 0.0,
        "repeat": 0.0,
        "punc": 0.0,
        "rhythm": 0.0
    }


func _reset_paragraph_stats():
    var current_time = Time.get_unix_time_from_system()
    paragraph_stats = {
        "words": [],         
        "puncs": [],         
        "word_lengths": [],  
        "natural_words": 0,  
        "repeated_words": 0, 
        "total_length": 0,         
        "total_words": 0,    
        # -------------
        "start_time": current_time,
        "end_time": current_time,     
        "duration": 0.0,          
        "input_words": 0,    # int
        "keys": 0,           
        "errors": 0,         
        "chars": 0,          
        "wpm": 0.0,          
        "kpm": 0.0,          
        "accuracy": 100.0,
        # -------------
        "score_style": 0,
        "rating_style": "NA",
        "rating_speed": "NA",
        "rating_accuracy": "NA",
    }


func incr_word(n=1):
    total_words += n
    update_stats()

    paragraph_stats.end_time = Time.get_unix_time_from_system()
    paragraph_stats.input_words += n
    _update_paragraph_stats()

func incr_error():
    wrong_chars += 1
    total_chars -= 1
    update_stats()

    paragraph_stats.errors += 1
    paragraph_stats.end_time = Time.get_unix_time_from_system()
    _update_paragraph_stats()
    print('incr error', wrong_chars, paragraph_stats.errors)

func incr_key(n = 1):
    total_keys += n
    total_chars += 1
    update_stats()

    if paragraph_stats.keys == 0:
        paragraph_stats.start_time = Time.get_unix_time_from_system()
    paragraph_stats.keys += n
    paragraph_stats.chars += 1
    paragraph_stats.end_time = Time.get_unix_time_from_system()
    _update_paragraph_stats()
    

func update_stats(is_tick=false) -> void:
    if !is_active: return
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
    if total_words >= typing_goal and !has_reached_goal:
        has_reached_goal = true
        goal_reached.emit()
    
    stats_updated.emit(is_tick)

func set_goal(chars: int) -> void:
    typing_goal = chars

func new_goal():
    goal_new.emit()

func start_goal():
    is_active = true
    _reset_stats()
    _reset_paragraph_stats()

func finish_goal():
    if has_reached_goal:
        _calculate_final_rating()
        goal_finished.emit()
        is_active = false
    else:
        print('goal is not reached')

func _calculate_final_rating() -> void:
    has_reached_goal = true
    # 速度评分 (WPM)
    speed_rating = match_rating(wpm, SPEED_SCORE_S)
    var speed_score = _calculate_lerped_score(wpm, SPEED_SCORE)
    
    # 准确度评分
    accuracy_rating = match_rating(accuracy, ACCURACY_SCORE_S)
    var accuracy_score = _calculate_lerped_score(accuracy, ACCURACY_SCORE)

    
    # 风格评分 (基于组合和特效使用)
    var style_score = _calc_overall_style_score()
    style_rating = match_rating(style_score, STYLE_SCORE_S)

    var final_score = _calc_final_score([speed_score, accuracy_score, style_score])
    final_rating = match_rating(final_score, FINAL_SCORE_S)

    prints('overall rating', speed_rating, accuracy_rating, style_rating)
    prints('got score', speed_score, accuracy_score, style_score, final_score, final_rating)
    print('final style scores', final_style_scores)

func _calc_final_score(scores):

    var total_score = 0.0
    for s in scores:
        total_score += s

    return total_score / scores.size()


func _calculate_lerped_score(value: float, thresholds: Dictionary) -> float:
    # 获取评级阈值的有序列表
    var ordered_thresholds = []
    for rating in thresholds:
        ordered_thresholds.append({
            "rating": rating,
            "value": thresholds[rating]
        })
    ordered_thresholds.sort_custom(func(a, b): return a.value < b.value)
    
    # 找到value所在的区间
    var prev_threshold = null
    var next_threshold = null
    
    for i in ordered_thresholds.size():
        if value >= ordered_thresholds[i].value:
            prev_threshold = ordered_thresholds[i]
            if i + 1 < ordered_thresholds.size():
                if value < ordered_thresholds[i + 1].value:
                    next_threshold = ordered_thresholds[i + 1]
                    break
    
    # 如果低于最低阈值
    if prev_threshold == null:
        return 40.0
    
    # 如果高于最高阈值
    if next_threshold == null:
        return 100.0
    
    # 使用实际的评分区间
    var base_score = {
        "SS": 100.0,
        "S": 95.0,
        "A": 90.0,
        "B": 80.0,
        "C": 70.0,
        "D": 40.0
    }
    
    var prev_score = base_score[prev_threshold.rating]
    var next_score = base_score[next_threshold.rating]

    
    # 计算插值权重
    var range_size = next_threshold.value - prev_threshold.value
    if value > next_threshold.value: 
        value = next_threshold.value
    var value_in_range = value - prev_threshold.value
    var weight = value_in_range / range_size

    
    # 在实际分数区间内插值
    return lerpf(next_score, prev_score, weight)

func _calc_overall_style_score():
    if paragraph_scores.is_empty():
        return 70.0

    final_style_scores = {
        "natural": 0.0,
        "repeat": 0.0,
        "punc": 0.0,
        "rhythm": 0.0
    }

    var total_weight = 0.0
    var weighted_sums = {
        "natural": 0.0,
        "repeat": 0.0,
        "punc": 0.0,
        "rhythm": 0.0,
        "overall": 0.0
    }

    # 计算加权总和
    for ps in paragraph_scores:
        var weight = ps.total_length
        total_weight += weight
        
        # 累加各个分项的加权分数
        weighted_sums.natural += ps.score_natural * weight
        weighted_sums.repeat += ps.score_repeat * weight
        weighted_sums.punc += ps.score_punc * weight
        weighted_sums.rhythm += ps.score_rhythm * weight
        weighted_sums.overall += ps.score_style * weight

    # 计算最终加权平均分
    if total_weight > 0:
        final_style_scores.natural = weighted_sums.natural / total_weight
        final_style_scores.repeat = weighted_sums.repeat / total_weight
        final_style_scores.punc = weighted_sums.punc / total_weight
        final_style_scores.rhythm = weighted_sums.rhythm / total_weight
        
        # 返回总体风格分数
        return weighted_sums.overall / total_weight

    return 70.0  # 默认分数

func match_rating(value: float, thresholds: Dictionary) -> String:
    for rating in thresholds:
        if value >= thresholds[rating]:
            return rating
    return "D"

func get_stats() -> Dictionary:
    var elapsed_seconds = (Time.get_unix_time_from_system() - start_time)
    return {
        "wpm": wpm,
        "kpm": kpm,
        "accuracy": accuracy,
        "progress": float(total_words) / typing_goal,
        "rating_speed": speed_rating,
        "rating_style": style_rating,
        "rating_accuracy": accuracy_rating,
        "rating_final": final_rating,
        "time": elapsed_seconds,
        "key": total_keys,
        "delete": wrong_chars,
        "word": total_words,
        "combo": max_combo,
        "goal": typing_goal,
        "style_scores": final_style_scores,
    }

# const en_symbols = [" ", ".", ",", "!", "?", ";", ":", "'", "\"", "`", "\n", "\t", "{", "}", "(", ")", "[", "]", "<", ">", "+", "-", "=", "*", "/"]
const cn_symbols = "　｀－＝［］、‘；／。，｜？》《：“｛｝＋—）（＊…％￥＃·！～’”〕〈〉「」『』〖〗【】＜＞"
const en_symbols = " .,!?;:'\"`\n\t{}()[]<>"
const cn_sep = "给的说对在和是被最所那这有将你会与他为不没很了啊哦呵把去届次集章第每只及于到也又我省县市镇村乡区"
const cn_full_pre_match = '应享给视及因对由关可看听来在也就如一其自这那多少才每或我没中始收也城乡节省村市别分'
const cn_next_match_word = {
        '城': '市',
        '乡': '镇村',
        '节': '省',
        '省': '钱心',
        '村': '庄',
        '市': '区',
        '区': '别分',
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
func update_combo(paragraph: String, count = 0) -> void:
    if !is_active: return
    if paragraph.length() <= 10: 
        _reset_paragraph_stats()
        return

    var current_time = Time.get_unix_time_from_system()

    _paragraph_input_sequence = []

    var ret = split_paragraph_words(paragraph)
    paragraph_stats.words = ret.words
    paragraph_stats.puncs = ret.puncs
    paragraph_stats.total_length = paragraph.length()

    # 分析每个词
    for word in paragraph_stats.words:
        if word.strip_edges() != "":
            _analyze_word(word, current_time)

    _calculate_style_rating()
    _update_paragraph_stats()
    combo_updated.emit()
    paragraph_scores.append({
        total_length=paragraph_stats.total_length,
        score_style=paragraph_stats.score_style, 
        wpm = paragraph_stats.wpm,
        accuracy = paragraph_stats.accuracy,
        rating_style = paragraph_stats.rating_style,
        rating_speed = paragraph_stats.rating_speed,
        rating_accuracy = paragraph_stats.rating_accuracy,
        score_natural = paragraph_stats.score_natural,
        score_repeat = paragraph_stats.score_repeat,
        score_punc = paragraph_stats.score_punc,
        score_rhythm = paragraph_stats.score_rhythm,
    })
    check_max_combo(count)
    print('get paragraph stats', paragraph_stats, paragraph_scores)

    await get_tree().process_frame
    _reset_paragraph_stats()

func check_max_combo(count):
    if max_combo < count: max_combo = count

# --------------


func split_paragraph_words(paragraph):
    # 分割段落为单词
    var current_word = ""
    var words = []
    var puncs = []

    var i = 0
    while i < paragraph.length():
        var c = paragraph[i]
        # 检查是否是中文字符
        if c.unicode_at(0) > 127:
            if c in cn_symbols:
                if current_word != "":
                    words.append(current_word)
                    current_word = ""
                    if c != '　': puncs.append(i)
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
                if c != ' ': puncs.append(i)
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

    return {words=final_words, puncs=puncs}

# --------------
func _update_paragraph_stats() -> void:
    if !is_active: return
    var elapsed_minutes = (paragraph_stats.end_time - paragraph_stats.start_time) / 60.0
    if elapsed_minutes > 0:
        # 计算段落WPM
        paragraph_stats.wpm = float(paragraph_stats.input_words) / elapsed_minutes
        paragraph_stats.kpm = float(paragraph_stats.keys) / elapsed_minutes
        
        # 计算段落准确度
        if paragraph_stats.chars > 0:
            var correct_chars = paragraph_stats.chars - paragraph_stats.errors
            paragraph_stats.accuracy = (float(correct_chars) / paragraph_stats.chars) * 100.0
        paragraph_stats.duration = paragraph_stats.end_time - paragraph_stats.start_time

# func get_paragraph_stats():
#     return {
#         "wpm": paragraph_stats.wpm,
#         "accuracy": paragraph_stats.accuracy,
#         "words": paragraph_stats.total_words,
#         "natural_ratio": float(paragraph_stats.natural_words) / paragraph_stats.total_words if paragraph_stats.total_words > 0 else 0.0,
#         "repeat_ratio": float(paragraph_stats.repeated_words) / paragraph_stats.total_words if paragraph_stats.total_words > 0 else 0.0,
#         "time": paragraph_stats.end_time - paragraph_stats.start_time,
#         "keys": paragraph_stats.keys,
#         "errors": paragraph_stats.errors
#     }


# 分析单词
func _analyze_word(word: String, time: float) -> void:
    paragraph_stats.total_words += 1

    if _paragraph_input_sequence.has(word):
        paragraph_stats.repeated_words += 1
    _paragraph_input_sequence.append(word)
    
    # 保持最近50个词的记录
    if _paragraph_input_sequence.size() > 50:
        _paragraph_input_sequence.pop_front()
    
    var word_length = word.length()
    paragraph_stats.word_lengths.append(word_length)

    # 检查是否是自然长度
    if _is_natural_word(word):
        paragraph_stats.natural_words += 1


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
        if char_counts[c] >= 4:
            prints('unnatural word:', word, 'total repeat char:', c)
            return true
            
        last_char = c
    
    return false


# 计算风格评分
func _calculate_style_rating() -> void:
    if paragraph_stats.total_words == 0:
        style_rating = "NA"
        return
    
    var paragraph_words = paragraph_stats.total_words
    var natural_words = paragraph_stats.natural_words
    # 计算自然长度得分
    var natural_ratio = float(natural_words) / paragraph_words
    # prints('unnatural', (paragraph_words - natural_words), natural_ratio)
    
    # 计算重复度得分（越低越好）
    var repeated_words = paragraph_stats.repeated_words
    var repetition_ratio = 1.0 - (float(repeated_words) / paragraph_words)
    # prints('repeat', repeated_words, repetition_ratio)
    
    # 计算节奏得分
    var rhythm_score = _calculate_rhythm_score()
    var punc_score = _calculate_punc_score()
    
    # 综合评分
    var final_score = (
        natural_ratio * STYLE_WEIGHTS.natural_length +
        repetition_ratio * STYLE_WEIGHTS.repetition +
        punc_score * STYLE_WEIGHTS.punctuation +
        rhythm_score * STYLE_WEIGHTS.rhythm
    ) * 100.0
    
    # 设置评级
    style_rating = match_rating(final_score, STYLE_SCORE_S)
    speed_rating = match_rating(paragraph_stats.wpm, SPEED_SCORE_S)
    accuracy_rating = match_rating(paragraph_stats.accuracy, ACCURACY_SCORE_S)
    paragraph_stats.score_natural = natural_ratio * 100.0
    paragraph_stats.score_repeat = repetition_ratio * 100.0
    paragraph_stats.score_punc = punc_score * 100.0
    paragraph_stats.score_rhythm = rhythm_score * 100.0
    paragraph_stats.score_style = final_score
    paragraph_stats.rating_style = style_rating
    paragraph_stats.rating_speed = speed_rating
    paragraph_stats.rating_accuracy = accuracy_rating

# 计算节奏得分
func _calculate_rhythm_score() -> float:
    var word_lengths = paragraph_stats.word_lengths
    if word_lengths.size() < 4:  # 至少需要4个词才能评估节奏
        return 1.0
    
    # 使用滑动窗口检查连续4个词的长度
    var rhythm_issues = 0
    var total_windows = 0
    var words = paragraph_stats.words
    
    for i in range(word_lengths.size() - 4):  # -3确保有4个词的窗口
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
                if length >= 3:
                    all_short = false
                    break
            if all_short:
                has_rhythm_issue = true
                issue_reason = "all short english words"
            
            var all_long = true
            for length in window:
                if length <= 16:
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

# 计算标点符号得分
func _calculate_punc_score() -> float:
    if not paragraph_stats.has("puncs"): return 0.8
        
    var puncs = paragraph_stats.puncs
    if puncs.size() == 0: return 0.8
        
    var total_length = paragraph_stats.total_length
    if total_length <= 10: return 1.0
        
    var issues = 0
    var last_punc_pos = -1
    
    # 检查标点符号的分布
    for punc_pos in puncs:
        # 检查标点间距
        if last_punc_pos != -1:
            var distance = punc_pos - last_punc_pos
            # 标点太密集（间距小于3个字符）
            if distance < 3:
                issues += 1
                prints("标点过密:", distance, "位置:", last_punc_pos, punc_pos)
            # 标点太稀疏（间距大于50个字符）
            elif distance > 80:
                issues += 1
                prints("标点过疏:", distance, "位置:", last_punc_pos, punc_pos)
        last_punc_pos = punc_pos
    
    # 检查首尾标点
    if total_length > 10:
        var end_punc = puncs[-1] if puncs.size() else -99
        # 结尾没有标点
        if total_length - end_punc > 10:
            issues += 1
            prints("结尾缺少标点:", total_length - puncs[-1])
    
    # 计算得分
    var punc_density = float(puncs.size()) / total_length
    # 理想的标点密度约为 0.1-0.15
    if punc_density < 0.01:
        issues += 1
        prints("标点太少:", punc_density)
    elif punc_density > 0.3:
        issues += 1
        prints("标点太多:", punc_density)
    
    var score = 1.0 - (issues * 0.1)  # 每个问题扣0.1分
    return max(0.0, score)  # 确保分数不小于0

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


func generate_match_maps(cn_full: Array) -> Dictionary:
    # 用 Dictionary 来模拟 set
    var pre_match = {}  # 用于存储所有词的第一个字
    var next_match = {} # 用于存储每个首字可能对应的后续字
    
    for word in cn_full:
        if word.length() >= 2:
            var first_char = word[0]
            var second_char = word[1]
            
            # 添加到首字集合
            pre_match[first_char] = true
            
            # 添加到后续字映射
            if not next_match.has(first_char):
                next_match[first_char] = {}
            next_match[first_char][second_char] = true
    
    # 转换为所需格式
    var pre_match_str = ""
    for char in pre_match.keys():
        pre_match_str += char
    
    # 转换 next_match 的值为字符串
    var next_match_dict = {}
    for key in next_match:
        var chars = ""
        for second_char in next_match[key].keys():
            chars += second_char
        next_match_dict[key] = chars
    
    return {
        "pre_match": pre_match_str,
        "next_match": next_match_dict
    }

# 使用示例
func _gen_cn_maps():
    var cn_full = ['应对','应该', '享有', '给予', '视为', '及其', '因为', '对于', '由于',
                   '关于', '可能', '因此', '如果', '因果', '看见', '可以', '看到', '听说', 
                   '听见', '听到', '就是', '也在', '一些', '一定', '其中', '自己','还有']
    
    var result = generate_match_maps(cn_full)
    print("cn_full_pre_match = '", result.pre_match, "'")
    print("cn_next_match_word = ", result.next_match)


# --------------
func get_paragraph_word_length(p):
    var ret = split_paragraph_words(p)
    return ret.words.size()

# -------------------
func split_paragraph_words_cjk(paragraph):
    # 分割段落为单词
    var current_word = ""
    var words = []
    var puncs = []

    var i = 0
    while i < paragraph.length():
        var c = paragraph[i]
        # 检查是否是中文字符
        if c.unicode_at(0) > 127:
            if c in cn_symbols:
                if current_word != "":
                    words.append(current_word)
                    current_word = ""
                    if c != '　': puncs.append(i)
            else:
                if current_word != "":
                    words.append(current_word)
                    current_word = c
                else:
                    current_word = c
        # 检查分隔符
        elif c in en_symbols:
            if current_word != "":
                words.append(current_word)
                current_word = ""
                if c != ' ': puncs.append(i)
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

    return {words=words, puncs=puncs}

func get_paragraph_word_length_cjk(p):
    var ret = split_paragraph_words_cjk(p)
    print('ret', ret)
    return ret.words.size()
