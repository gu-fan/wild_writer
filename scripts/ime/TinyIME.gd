# scripts/ime/tiny_ime.gd
extends IMEBase

var context: CompositionContext
var processor: InputProcessor
var matcher: PinyinMatcher
var page_size: int  : get = get_page_size, set = set_page_size

func _init():
    context = CompositionContext.new()
    matcher = PinyinMatcher.new()
    processor = InputProcessor.new(context, matcher)
    
    # 连接信号
    processor.composition_updated.connect(_on_composition_updated)
    processor.text_committed.connect(_on_text_committed)

func _ready():
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

func _on_text_committed(text: String) -> void:
    emit_signal("ime_text_changed", text)

# 重写基类方法
func toggle() -> void:
    super.toggle()
    if not is_active:
        context.reset()

func reset() -> void:
    context.reset()
    emit_signal("composition_updated")

# 设置页面大小
func set_page_size(size: int) -> void:
    context.set_page_size(size)

# 获取页面大小
func get_page_size() -> int:
    return context.get_page_size()

# 切换双拼模式
func toggle_shuangpin() -> void:
    matcher.shuangpin_enabled = not matcher.shuangpin_enabled
    context.reset()
