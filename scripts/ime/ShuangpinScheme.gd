class_name ShuangpinScheme

# 声母映射
const INITIALS = {
    "a": "",    # 零声母
    "b": "b",
    "c": "c",
    "d": "d",
    "e": "",
    "f": "f",
    "g": "g",
    "h": "h",
    "i": "ch",    # 零声母
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
    "u": "sh",    # 零声母
    "v": "zh",  # 特殊声母
    "w": "w",
    "x": "x",
    "y": "y",
    "z": "z"
}

# 韵母映射
const FINALS = {
    "iu": "q",
    "ei": "w",
    "e": "e",
    "uan": "r",
    "ue": "t",
    "ve": "t",
    "un": "y",
    "u": "u",
    "i": "i",
    "o": "o",
    "uo": "o",
    "ie": "p",
    "a": "a",
    "iong": "s",
    "ong": "s",
    "ai": "d",
    "en": "f",
    "eng": "g",
    "ang": "h",
    "an": "j",
    "ing": "k",
    "uai": "k",
    "uang": "l",
    "iang": "l",
    "ou": "z",
    "ia": "x",
    "ua": "x",
    "ao": "c",
    "ui": "v",
    "v": "v",
    "in": "b",
    "iao": "n",
    "ian": "m",
}

# 零声母韵母映射
const ZERO_FINALS = {
    "aa" :"a",   
    "ai" :"ai",  
    "an" :"an",  
    "ah" :"ang", 
    "ao" :"ao",  
    "ee" :"e",   
    "ei" :"ei",  
    "en" :"en",  
    "eg" :"eng", 
    "er" :"er",  
    "oo" :"o",   
    "ou" :"ou",  
}

# 将双拼转换为全拼
static func convert_to_pinyin(shuangpin: String, trie) -> Array:
    # var results: Array[String] = []
    var results: Array = []
    
    # 每两个字符为一组
    for i in range(0, shuangpin.length(), 2):
        if i + 1 >= shuangpin.length():
            results.append(shuangpin[i])
            break
            
        var first = shuangpin[i]
        var second = shuangpin[i + 1]
        var pair = first + second
        
        if pair in ZERO_FINALS:
            results.append(ZERO_FINALS[pair])
            continue
            
        var initial = INITIALS.get(first, "")
        var finals = []
        
        for f in FINALS:
            if FINALS[f] == second:
                var matches = trie.search(initial + f)
                if matches.size():
                    finals.append(f)
                    break

        if finals.is_empty():
            return results
         
        for final in finals:
            if initial != "" and final != "":
                results.append(initial + final)
            elif final != "":
                results.append(final)
    
    return results
