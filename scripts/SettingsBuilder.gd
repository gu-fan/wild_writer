class_name SettingsBuilder

const SETTING_SCENE = preload("res://scenes/setting_item.tscn")

static func build_settings(container: Control, config: Dictionary, section: String) -> void:
    # 直接遍历配置中的键值对
    for key in config:
        var setting = config[key]  # setting是一个字典，包含type、default等属性
        var item = _create_setting_item(section, key, setting)
        container.add_child(item)
        print('add child', item, item.is_inside_tree(),item.size, item.visible)

static func _create_section(name: String) -> Control:
    var section = VBoxContainer.new()
    
    var label = Label.new()
    label.text = name.capitalize()
    label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    section.add_child(label)
    
    return section

static func _create_setting_item(section: String, key: String, config: Dictionary) -> Control:

    var item = SETTING_SCENE.instantiate()
    item.name = key
    
    # 设置标签
    item.get_node("Label").text = config.get("label", key)
    
    # 获取当前值
    var current_value = SettingManager.get_setting(section, key)
    
    # 根据类型创建控制器
    match config.type:
        "bool":
            var checkbox = CheckButton.new()
            checkbox.button_pressed = current_value  # 使用当前值
            checkbox.toggled.connect(
                func(pressed): SettingManager.set_setting(section, key, pressed)
            )
            item.add_child(checkbox)
            
        "int":
            var spinbox = SpinBox.new()
            spinbox.min_value = config.get("min", 0)
            spinbox.max_value = config.get("max", 100)
            spinbox.value = current_value  # 使用当前值
            spinbox.value_changed.connect(
                func(value): SettingManager.set_setting(section, key, value)
            )
            item.add_child(spinbox)
            
        "shortcut":
            var button = Button.new()
            button.text = SettingManager.get_key_shown(current_value)  # 使用当前值
            button.custom_minimum_size.x = 100
            button.pressed.connect(
                func(): _setup_shortcut(button, section, key)
            )
            item.add_child(button)
    
    print('build item', section, key, config, item, item.size)
    return item

static func _setup_shortcut(button: Button, section: String, key: String) -> void:
    # 创建一个临时的KeyCapture节点
    var key_capture = KeyCapture.new()
    button.get_tree().root.add_child(key_capture)
    
    key_capture.show_key_capture()
    var captured_key = await key_capture.key_captured
    
    if captured_key:
        button.text = SettingManager.get_key_shown(captured_key)
        SettingManager.set_setting(section, key, captured_key)
    
    key_capture.queue_free()
