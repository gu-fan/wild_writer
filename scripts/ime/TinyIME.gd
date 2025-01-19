# scripts/ime/tiny_ime.gd
extends IMEBase

var context: CompositionContext
var processor: InputProcessor
var matcher: PinyinMatcher
var page_size: int  : get = get_page_size, set = set_page_size
var _is_fullwidth = false

func _init():
    context = CompositionContext.new()
    matcher = PinyinMatcher.new()
    processor = InputProcessor.new(context, matcher)
    
    # 连接信号
    processor.composition_updated.connect(_on_composition_updated)
    processor.buffer_changed.connect(_on_buffer_changed)
    processor.text_committed.connect(_on_text_committed)

func _ready():
    await get_tree().create_timer(0.5)
    matcher.load_dictionary("res://scripts/google_pinyin.txt")

# 添加 _input 处理
func _input(event: InputEvent) -> void:
    if is_disabled:
        return
    if not is_active:
        return
        
    process_input(event)

# 实现基类的 process_input 方法
func process_input(event: InputEvent) -> void:
    if event is InputEventKey:
        if processor.process_key(event):
            get_viewport().set_input_as_handled()

func get_state() -> Dictionary:
    var base_state = super.get_state()
    base_state.merge(context.get_state())
    return base_state

func _on_composition_updated() -> void:
    emit_signal("composition_updated")
func _on_buffer_changed(buf, is_partial_feed=false) -> void:
    emit_signal("ime_buffer_changed", buf, is_partial_feed)
func _on_text_committed(text: String) -> void:
    emit_signal("ime_text_changed", text)

func toggle() -> void:
    super.toggle()
    if not is_active:
        context.reset()

func reset() -> void:
    context.reset()
    emit_signal("composition_updated")

func set_page_size(size: int) -> void:
    context.set_page_size(size)

func get_page_size() -> int:
    return context.get_page_size()

func toggle_shuangpin() -> void:
    matcher.shuangpin_enabled = not matcher.shuangpin_enabled
    context.reset()
func set_shuangpin(v):
    matcher.shuangpin_enabled = v
    context.reset()

# -------------
# NOT USED
func update_settings(settings: Dictionary) -> void:
    if "page_size" in settings:
        set_page_size(settings.page_size)
    if "shuangpin" in settings:
        matcher.shuangpin_enabled = settings.shuangpin
    if "fuzzy" in settings:
        matcher.fuzzy_enabled = settings.fuzzy
# -------------
func set_key(k, v):
    processor.keys[k] = v

func set_fullwidth(v:bool):
    _is_fullwidth = v
func toggle_fullwidth():
    _is_fullwidth = !_is_fullwidth

func is_fullwidth():
    return is_active and _is_fullwidth

const FULLWIDTH_PUNC = ',.!?:;@#$%^&\'"`<>(){}[]+-*\\=~'
func will_process_fullwidth(c:String):
    return is_fullwidth() and c in FULLWIDTH_PUNC

const FULLWIDTH_PUNC_DIC = {
        ',': '，',
        '.': '。',
        '!': '！',
        '?': '？',
        ':': '：',
        ';': '；',
        '@': '＠',
        '#': '＃',
        '$': '¥',
        '%': '％',
        '&': '＆',
        '^': '……',
        '\'': '‘’',
        '"': '“”',
        '`': '·',
        '<': '《',
        '>': '》',
        '(': '（',
        ')': '）',
        '{': '「',
        '}': '」',
        '[': '【',
        ']': '】',
        '+': '＋',
        '-': '－',
        '*': '＊',
        '\\': '＼',
        '=': '＝',
        '~': '〜',
    }
var _sequence_punc = {'"': 0,'\'':0}
func get_fullwidth(c:String):
    if c in _sequence_punc:
        if _sequence_punc[c] == 0:
            _sequence_punc[c] = 1
            return FULLWIDTH_PUNC_DIC[c][0]
        else:
            _sequence_punc[c] = 0
            return FULLWIDTH_PUNC_DIC[c][1]
    else:
        return FULLWIDTH_PUNC_DIC[c]
