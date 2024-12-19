class_name ShuangpinScheme

# 声母映射
const INITIALS = {
    "a": "",    # 零声母
    "b": "b",
    "c": "c",
    "d": "d",
    "f": "f",
    "g": "g",
    "h": "h",
    "i": "",    # 零声母
    "j": "j",
    "k": "k",
    "l": "l",
    "m": "m",
    "n": "n",
    "o": "",    # 零声母
    "p": "p",
    "q": "q",
    "r": "r",
    "s": "s",
    "t": "t",
    "u": "",    # 零声母
    "v": "zh",  # 特殊声母
    "w": "w",
    "x": "x",
    "y": "y",
    "z": "z"
}

# 韵母映射
const FINALS = {
    "a": "a",
    "ai": "l",
    "an": "j",
    "ang": "h",
    "ao": "k",
    "e": "e",
    "ei": "z",
    "en": "f",
    "eng": "g",
    "er": "r",
    "i": "i",
    "ia": "w",
    "ian": "m",
    "iang": "d",
    "iao": "c",
    "ie": "x",
    "in": "n",
    "ing": ";",
    "iong": "s",
    "iu": "q",
    "o": "o",
    "ong": "s",
    "ou": "b",
    "u": "u",
    "ua": "w",
    "uai": "y",
    "uan": "r",
    "uang": "d",
    "ue": "t",
    "ui": "v",
    "un": "p",
    "uo": "o",
    "v": "v",
    "ve": "t"
}

# 零声母韵母映射
const ZERO_FINALS = {
    "a": "aa",
    "ai": "ai",
    "an": "an",
    "ang": "ah",
    "ao": "ao",
    "e": "ee",
    "ei": "ei",
    "en": "en",
    "eng": "eg",
    "er": "er",
    "o": "oo",
    "ou": "ou"
}

# 将双拼转换为全拼
static func convert_to_pinyin(shuangpin: String) -> Array[String]:
    var results: Array[String] = []
    
    # 每两个字符为一组
    for i in range(0, shuangpin.length(), 2):
        if i + 1 >= shuangpin.length():
            break
            
        var first = shuangpin[i]
        var second = shuangpin[i + 1]
        var pair = first + second
        
        # 1. 检查是否是零声母特殊组合
        if pair in ZERO_FINALS:
            results.append(ZERO_FINALS[pair])
            continue
            
        # 2. 分别获取声母和韵母
        var initial = INITIALS.get(first, "")
        var final = ""
        
        # 查找对应的韵母
        for f in FINALS:
            if FINALS[f] == second:
                final = f
                break
        
        if initial != "" and final != "":
            results.append(initial + final)
        elif final != "":
            results.append(final)
    
    return results 
