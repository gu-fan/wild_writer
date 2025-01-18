class_name KeySystem
extends Node

signal sequence_matched(binding: KeyBinding)

class KeyBinding:
    var sequence: Array[String]
    var command: String
    var when: String
    var args: Dictionary
    var shown: Array[String]
    
    func _init(seq: Array[String], cmd: String, when_condition: String = "", arguments: Dictionary = {}):
        sequence = seq
        command = cmd
        when = when_condition
        args = arguments
        for s in sequence:
            shown.append(ConfigManager.get_key_shown(s))

var bindings: = {}

func set_binding(sequence: Array[String], command: String, when: String = "", args: Dictionary = {}) -> void:
    bindings[command] = KeyBinding.new(sequence, command, when, args)

func handle_input(event: InputEventKey) -> void:

    var key_name = event.as_text_keycode()
    for cmd in bindings:
        var binding = bindings[cmd]
        var ks = Editor.config.get_key_shown(key_name)
        if binding.shown[0] == ks:
            emit_signal("sequence_matched", binding)
            get_viewport().set_input_as_handled()
            return
