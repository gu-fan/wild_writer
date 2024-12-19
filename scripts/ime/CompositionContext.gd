# scripts/ime/core/composition_context.gd
class_name CompositionContext

signal page_size_changed(new_size: int)

var buffer: String = ""
var candidates: Array = []
var candidates_matched_lengths: Array = []
var current_selection: int = 0
var current_page: int = 0
var page_size: int = 5  : get = get_page_size, set = set_page_size

# Getter
func get_page_size() -> int:
    return page_size

# Setter
func set_page_size(value: int) -> void:
    if value > 0:  # 确保页面大小有效
        page_size = value
        emit_signal("page_size_changed", value)

func reset() -> void:
    buffer = ""
    candidates.clear()
    candidates_matched_lengths.clear()
    current_selection = 0
    current_page = 0

func get_state() -> Dictionary:
    return {
        "buffer": buffer,
        "candidates": candidates,
        "current_selection": current_selection,
        "current_page": current_page,
        "page_size": page_size
    }

# 检查是否有候选词
func has_candidates() -> bool:
    return not candidates.is_empty()
