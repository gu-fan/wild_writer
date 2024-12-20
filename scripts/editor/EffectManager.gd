class_name EffectManager
extends Node

signal effect_triggered(effect_name: String, params: Dictionary)

var effects: Dictionary = {}
var effect_settings: Dictionary = {}

func register_effect(name: String, scene: PackedScene):
    effects[name] = scene

func trigger_effect(name: String, params: Dictionary = {}):
    if effects.has(name):
        emit_signal("effect_triggered", name, params)
