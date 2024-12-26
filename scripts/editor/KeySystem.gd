class_name KeySystem
extends Node

signal sequence_matched(binding: KeyBinding)

class KeyBinding:
    var sequence: Array[String]
    var command: String
    var when: String
    var args: Dictionary
    
    func _init(seq: Array[String], cmd: String, when_condition: String = "", arguments: Dictionary = {}):
        sequence = seq
        command = cmd
        when = when_condition
        args = arguments

var bindings: Array[KeyBinding] = []

func add_binding(sequence: Array[String], command: String, when: String = "", args: Dictionary = {}) -> void:
    bindings.append(KeyBinding.new(sequence, command, when, args))

func handle_input(event: InputEventKey) -> void:

    ## 检查是否是快捷键组合
    #var key_sequence = []
    #if event.ctrl_pressed:  key_sequence.append("Ctrl")
    #if event.shift_pressed: key_sequence.append("Shift")
    #if event.alt_pressed:   key_sequence.append("Alt")
    
    ## 添加主键
    #var key_name = OS.get_keycode_string(event.keycode)
    #key_sequence.append(key_name)
    #print('la',  event.as_text_key_label())
    #print('lo',  event.as_text_location())
    #print('km',  event.get_keycode_with_modifiers())
    #print('ky ', event.keycode)
    #print('un',  event.unicode)
    #print('kn',  key_name)
    
    ##) 将序列转换为标准格式（例如：["Ctrl", "S"] -> "Ctrl+S"）
    #var sequence_str = "+".join(key_sequence)
    
    ## 检查是否匹配任何绑定
    #for binding in bindings:
    #    if binding.sequence.size() == 1 and binding.sequence[0] == sequence_str:
    #        emit_signal("sequence_matched", binding)
    #        get_viewport().set_input_as_handled()
    #        return

    # print('ke', key_name)
    # print('lm', event.get_key_label_with_modifiers())
    var key_name = event.as_text_keycode()
    for binding in bindings:
       if binding.sequence[0] == key_name:
           emit_signal("sequence_matched", binding)
           get_viewport().set_input_as_handled()
           return
