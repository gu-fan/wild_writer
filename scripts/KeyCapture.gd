class_name KeyCapture extends Node

signal key_captured(key)

# 快捷键捕获相关
var _key_capture_dialog: Window
var _waiting_key = false

func show_key_capture():
    if _key_capture_dialog:
        _key_capture_dialog.queue_free()
    
    # 创建捕获窗口
    _key_capture_dialog = KeyCaptureDialog.new()
    _key_capture_dialog.title = "按下快捷键"
    _key_capture_dialog.size = Vector2(300, 100)
    _key_capture_dialog.unresizable = true
    _key_capture_dialog.exclusive = true
    
    # 添加提示标签
    var label = Label.new()
    label.text = "请按下快捷键..."
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.anchors_preset = Control.PRESET_FULL_RECT
    label.name = 'Label'
    
    _key_capture_dialog.add_child(label)
    get_tree().root.add_child(_key_capture_dialog)
    _key_capture_dialog.popup_centered()
    
    _waiting_key = true
    # set_process_input(true)

    _key_capture_dialog.close_requested.connect(_on_dialog_close)
    _key_capture_dialog.key_captured.connect(_on_dialog_key)
    _key_capture_dialog.mod_captured.connect(_on_dialog_mod)

func _on_dialog_mod(k):
    _key_capture_dialog.get_node('Label').text = k

func _on_dialog_key(k):
    emit_signal("key_captured", k)
    _waiting_key = false
    _key_capture_dialog.queue_free()
    _key_capture_dialog = null

func _on_dialog_close():
    emit_signal("key_captured")
    _waiting_key = false
    # set_process_input(false)
    _key_capture_dialog.queue_free()
    _key_capture_dialog = null

class KeyCaptureDialog extends Window:
    signal key_captured(k)
    signal mod_captured(k)

    func _input(event):
        if event is InputEventKey and event.pressed:
            var key_string = ""
            
            # 添加修饰键
            if event.ctrl_pressed:
                key_string += "Ctrl+"
            if event.shift_pressed:
                key_string += "Shift+"
            if event.alt_pressed:
                key_string += "Alt+"

                
            # 添加主键
            var keycode = OS.get_keycode_string(event.keycode)
            emit_signal('mod_captured', key_string + keycode)
            if keycode:
                match keycode:
                    'Shift': return
                    'Ctrl': return
                    'Alt': return
                    'Win': return
                    _: key_string += keycode
            
            emit_signal('key_captured', key_string)
