# scripts/ime/core/ime_base.gd
class_name IMEBase
extends Node

signal ime_text_changed(text: String)
signal ime_state_changed(active: bool)
signal composition_updated

# 基础IME状态
var is_active: bool = false
var is_disabled: bool = false

# 虚函数，子类需要实现
func process_input(event: InputEvent) -> void:
    pass

func reset() -> void:
    pass

func toggle() -> void:
    is_active = !is_active
    emit_signal("ime_state_changed", is_active)
    if not is_active:
        reset()

func get_state() -> Dictionary:
    return {
        "is_active": is_active,
        "is_disabled": is_disabled
    }
