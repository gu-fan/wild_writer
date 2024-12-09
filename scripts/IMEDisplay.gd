extends Control

signal feed_ime_input(text)

@onready var ime = TinyIME
@onready var pinyin_label = $PinyinLabel
@onready var candidates_container: HBoxContainer = $Panel/CandidatesContainer
@onready var panel = $Panel

func _ready():
    ime.ime_text_changed.connect(_on_ime_text_changed)
    pinyin_label.set("theme_override_font_sizes/font_size", 20)

func _process(_delta):
    var state = ime.get_current_state()
    pinyin_label.text = state.pinyin
    update_candidates_display(state.candidates)

    panel.visible = !state.pinyin.is_empty()

func update_candidates_display(candidates: Array) -> void:
    # Clear existing candidates first
    for child in candidates_container.get_children():
        child.queue_free()
    
    var state = ime.get_current_state()
    var start_idx = state.current_page * state.page_size
    var end_idx = min(start_idx + state.page_size, candidates.size())
    
    
    # Create new labels for visible candidates
    for i in range(start_idx, end_idx):
        var label = Label.new()
        var display_number = (i - start_idx) + 1
        label.text = "%d.%s" % [display_number, candidates[i]]
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.custom_minimum_size = Vector2(40, 30)
        label.set("theme_override_font_sizes/font_size", 20)
        candidates_container.add_child(label)

    # Add navigation indicator if needed
    if state.current_page > 0:
        var prev_label = Label.new()
        prev_label.text = "["
        prev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        prev_label.custom_minimum_size = Vector2(10, 30)
        prev_label.set("theme_override_font_sizes/font_size", 20)
        candidates_container.add_child(prev_label)
    
    # Add next page indicator if needed
    if (state.current_page + 1) * state.page_size < candidates.size():
        var next_label = Label.new()
        next_label.text = "]"
        next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        next_label.custom_minimum_size = Vector2(10, 30)
        next_label.set("theme_override_font_sizes/font_size", 20)
        candidates_container.add_child(next_label)

func _on_ime_text_changed(text: String) -> void:
    # 处理选中的文字
    # print(text)
    # editor.feed_ime_input()
    emit_signal('feed_ime_input', text)
