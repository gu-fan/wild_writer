extends Node

signal ime_text_changed(text: String)
signal ime_state_changed(v)


var pinyin_buffer: String = ""
var candidates: Array = []
var candidates_matched_lengths: Array = []
var current_selection: int = 0
var is_ime_active: bool = false
var disabled: bool = false

# 简单的拼音到汉字的映射字典
var pinyin_dict = {}

# 修改频率字典的结构，使用 {char: {pinyin: freq}} 的形式
var char_frequencies: Dictionary = {}

var page_size: int = 5
var current_page: int = 0

# 添加字母缓存字典
var pinyin_dict_cache = {}

func _ready():
    _lpd()
    _bpc()

func _lpd():
    var f=FileAccess.open("res://scripts/google_pinyin.txt",FileAccess.READ)
    if!f:print("Failed to load pinyin dictionary");return
    while!f.eof_reached():
        var l=f.get_line().strip_edges()
        if l.is_empty() or l.begins_with("#"):continue
        var p=l.split(" ",false,3)
        if p.size()<4:continue
        var c=p[0]
        var q=p[1].to_float()
        if p[2]=="1":continue
        var y=p[3].replace(" ","")
        if!char_frequencies.has(c):char_frequencies[c]={}
        char_frequencies[c][y]=q
        if!pinyin_dict.has(y):pinyin_dict[y]=[]
        pinyin_dict[y].append(c)

func _bpc():
    for i in range(97,123):pinyin_dict_cache[char(i)]=[]
    for y in pinyin_dict:
        var c=y[0]
        if c in pinyin_dict_cache:pinyin_dict_cache[c].append(y)

func _input(event: InputEvent) -> void:
    if disabled: return
    if not is_ime_active: return
        
    if event is InputEventKey and event.pressed: _hki(event)

func _hki(event: InputEventKey) -> void:
    var key_string = OS.get_keycode_string(event.get_keycode_with_modifiers())
    var unicode = event.keycode
    
    # 处理特殊键
    match key_string:
        "Escape":  # 取消输入
            reset_ime()
            get_viewport().set_input_as_handled()
            return
        "Enter", "Return":  # 回车键处理
            if pinyin_buffer.length() > 0:
                if candidates.size() > 0:
                    # 有候选词时输入第一个
                    # emit_signal("ime_text_changed", candidates[0])
                    _hcs(0)
                else:
                    # 没有候选词时直接入拼音
                    emit_signal("ime_text_changed", pinyin_buffer)
                    reset_ime()
                get_viewport().set_input_as_handled()
                return
        "Backspace":  # 删除字符
            if pinyin_buffer.length() > 0:
                pinyin_buffer = pinyin_buffer.substr(0, pinyin_buffer.length() - 1)
                if pinyin_buffer.length() == 0:
                    reset_ime()
                else:
                    _uc()
                get_viewport().set_input_as_handled()
                return

    if SettingManager.is_match_shortcut(key_string, 'ime', 'prev_page_key'):
        if !pinyin_buffer.is_empty():
            get_viewport().set_input_as_handled()
        if current_page > 0:
            current_page -= 1
            return
    if SettingManager.is_match_shortcut(key_string, 'ime', 'next_page_key'):
        if !pinyin_buffer.is_empty():
            get_viewport().set_input_as_handled()
        if (current_page + 1) * page_size < candidates.size():
            current_page += 1
            return
    
    # Handle number keys for selection (1-5)
    if candidates.size() > 0 and key_string.is_valid_int():
        var num = key_string.to_int() - 1  # Convert to 0-based index
        var actual_index = current_page * page_size + num
        if num >= 0 and num < page_size and actual_index < candidates.size():
            # emit_signal("ime_text_changed", candidates[actual_index])
            _hcs(actual_index)
            # reset_ime()
            get_viewport().set_input_as_handled()
            return
    
    # 处理拼音输入
    if key_string.length()==1 and key_string.is_valid_identifier():
        if pinyin_buffer.length()<15:
            pinyin_buffer+=key_string.to_lower()
            _uc()
        get_viewport().set_input_as_handled()


func _gsm(b:String)->Array:
    var s=[]
    var m=[]
    var f=0.0
    var p=0
    var l=0
    while p<b.length():
        var h=0
        for i in range(6,0,-1):
            if p+i>b.length():continue
            var g=b.substr(p,i)
            if g.length()>0:
                var c=g[0]
                if c in pinyin_dict_cache:
                    for y in pinyin_dict_cache[c]:
                        if y==g and g in pinyin_dict:
                            var x=""
                            var q=0.0
                            for r in pinyin_dict[g]:
                                if r in char_frequencies and g in char_frequencies[r]:
                                    var w=char_frequencies[r][g]
                                    if w>q:q=w;x=r
                            if q>1e3:
                                m.append(x)
                                f+=q
                                p+=i
                                l=p
                                h=1
                                break
                    if h:break
        if!h:break
    if m.size()>0:
        var j="".join(m)
        var a=f/m.size()
        if a>1e3:s.append({"char":j,"freq":a,"matched_length":l})
    return s

func _gem(b:String)->Array:
    var e=[]
    if b in pinyin_dict:
        for c in pinyin_dict[b]:
            var f=0.0
            if c in char_frequencies and b in char_frequencies[c]:
                f=char_frequencies[c][b]
            e.append({"char":c,"freq":f,"matched_length":b.length()})
    return e

func _gpm(b:String)->Array:
    var p=[]
    if b.length()>0:
        var c=b[0]
        if c in pinyin_dict_cache:
            for k in pinyin_dict_cache[c]:
                if p.size()>=10:break
                if k.begins_with(b)and k!=b:
                    for h in pinyin_dict[k]:
                        var f=0.0
                        if h in char_frequencies and k in char_frequencies[h]:
                            f=char_frequencies[h][k]
                        if f>750.0:
                            p.append({"char":h,"freq":f,"matched_length":b.length()})
    return p

func _uc()->void:
    candidates.clear()
    candidates_matched_lengths.clear()
    current_selection=0
    current_page=0
    var c=[]
    var s={}
    var e=_gem(pinyin_buffer)
    var g=_gsm(pinyin_buffer)
    var p=_gpm(pinyin_buffer)
    if e.size()>0:
        e.sort_custom(func(a,b):return a["freq"]>b["freq"])
        for m in e:
            if!s.has(m["char"]):
                c.append(m)
                s[m["char"]]=1
        if e.size()<page_size:
            for m in g:
                if!s.has(m["char"]):
                    c.append(m)
                    s[m["char"]]=1
            for m in p:
                if!s.has(m["char"]):
                    c.append(m)
                    s[m["char"]]=1
    else:
        for m in g:
            if!s.has(m["char"]):
                c.append(m)
                s[m["char"]]=1
        for m in p:
            if!s.has(m["char"]):
                c.append(m)
                s[m["char"]]=1
        c.sort_custom(func(a,b):return a["freq"]>b["freq"])
    for i in c:
        candidates.append(i["char"])
        candidates_matched_lengths.append(i["matched_length"])

func reset_ime() -> void:
    pinyin_buffer = ""
    candidates.clear()
    current_selection = 0
    current_page = 0

func toggle_ime() -> void:
    is_ime_active = !is_ime_active
    emit_signal('ime_state_changed', is_ime_active)
    if not is_ime_active:
        reset_ime()

func get_current_state() -> Dictionary:
    return {
        "pinyin": pinyin_buffer,
        "candidates": candidates,
        "current_selection": current_selection,
        "is_active": is_ime_active,
        "current_page": current_page,
        "page_size": page_size
    }

func _hcs(index: int) -> void:
    if index >= candidates.size() or index >= candidates_matched_lengths.size():
        reset_ime()
        return
        
    var selected_char = candidates[index]
    var matched_length = candidates_matched_lengths[index]
    
    # 如果还有未匹配的拼音，留在buffer中
    if matched_length < pinyin_buffer.length():
        # 保留未匹配的部分
        var remaining = pinyin_buffer.substr(matched_length)
        
        if remaining.length() > 0:
            emit_signal("ime_text_changed", selected_char)
            var temp_buffer = remaining
            pinyin_buffer = temp_buffer
            _uc()  # 更新候选列表
            return
    
    # 如果是完全匹配或没有剩余部分
    emit_signal("ime_text_changed", selected_char)
    reset_ime()

func h2f(u):
    return String.chr(u + 0xfee0)
func f2h(u):
    return String.chr(u - 0xfee0)
