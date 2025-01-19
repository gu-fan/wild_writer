class_name SettingsBuilder

const SETTING_SCENE = preload("res://scenes/setting_item.tscn")

static func build_settings(container: Control, config: Dictionary, section: String) -> void:
    # 直接遍历配置中的键值对
    for key in config[section]:
        var setting = config[section][key]  # setting是一个字典，包含type、default等属性
        var item = _create_setting_item(section, key, setting)
        container.add_child(item)

static func _create_setting_item(section: String, key: String, config: Dictionary) -> Control:
    var item = SETTING_SCENE.instantiate()
    item.name = key
    
    # 设置标签
    item.get_node("Label").text = config.get("label", key)

    var lb_desc = RichTextLabel.new()
    lb_desc.custom_minimum_size = Vector2(300, 28)
    lb_desc.fit_content = true
    lb_desc.scroll_active = false
    lb_desc.text = config.get("desc", '')
    lb_desc.bbcode_enabled = true
    lb_desc.size_flags_vertical = 0
    lb_desc.name = 'RichText'
    item.add_child(lb_desc)
    
    # 获取当前值
    var current_value = Editor.config.get_setting(section, key)
    var control: Control
    
    # 根据类型创建控制器
    match config.type:
        "bool":
            var checkbox = CheckButton.new()
            checkbox.button_pressed = current_value
            checkbox.toggled.connect(
                func(pressed): Editor.config.set_setting(section, key, pressed)
            )
            control = checkbox
            Editor.config.subscribe(section, key, control, 
                func(value): control.set_pressed_no_signal(value)
            )

            control.name = 'bool'
            item.get_node('Control').add_child(control)
            
        "int":
            var slider = HSlider.new()

            slider.min_value = config.get("min", 0)
            slider.max_value = config.get("max", 3)
            slider.value = current_value
            slider.tick_count = slider.max_value - slider.min_value + 1
            slider.ticks_on_borders = true
            slider.custom_minimum_size = Vector2(135, 20)

            slider.value_changed.connect(
                func(value): Editor.config.set_setting(section, key, value)
            )

            control = slider

            control.name = 'int'
            item.get_node('Control').add_child(control)

            if config.has('keys'):
                var lb_key = Label.new()
                lb_key.text = config.keys[current_value]
                lb_key.custom_minimum_size = Vector2(35, 28)
                lb_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                lb_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
                UI.set_font_color(lb_key, '888888')
                item.get_node('Control').add_child(lb_key)
                item.get_node('Control').custom_minimum_size.x = 170
                item.get_node('RichText').custom_minimum_size.x = 300 - 20
                Editor.config.subscribe(section, key, control, 
                    func(value): 
                        control.set_value_no_signal(value)
                        lb_key.text = config.keys[value]
                )
            else:
                Editor.config.subscribe(section, key, control, 
                    func(value): control.set_value_no_signal(value)
                )

                
        "shortcut":
            var button = Button.new()
            button.text = Editor.config.get_key_shown(current_value)
            button.custom_minimum_size.x = 100
            button.pressed.connect(
                func(): _setup_shortcut(button, section, key)
            )
            control = button
            Editor.config.subscribe(section, key, control, 
                func(value): control.text = Editor.config.get_key_shown(value)
            )
            control.name = 'shortcut'
            item.get_node('Control').add_child(control)

        "option":
            var opts = config.get('options', [])
            var button = create_option(opts, 
                    func(v): Editor.config.set_setting(section, key, v)
                ,current_value)
            button.custom_minimum_size.x = 100
            button.focus_mode = 0
            control = button
            control.name = 'option'
            Editor.config.subscribe(section, key, control, 
                func(value): control.select(value)
            )
            item.get_node('Control').add_child(control)
        "directory":
            var button = Button.new()
            button.text = current_value
            button.custom_minimum_size.x = 180
            button.clip_text = true
            item.get_node('Control').custom_minimum_size.x = 190
            item.get_node('RichText').custom_minimum_size.x = 300 - 40
            button.pressed.connect(
                func(): _setup_directory(button, section, key) 
            )
            control = button
            Editor.config.subscribe(section, key, control, 
                func(value): control.text = value
            )
            item.get_node('Control').add_child(control)
        "string":
            var input = LineEdit.new()
            input.text = current_value
            if config.has('placeholder'):
                input.placeholder_text = config.placeholder
            input.custom_minimum_size.x = 180
            input.drag_and_drop_selection_enabled = false
            item.get_node('Control').custom_minimum_size.x = 190
            item.get_node('RichText').custom_minimum_size.x = 300 - 40
            input.text_changed.connect(
                func(v): Editor.config.set_setting(section, key, v)
            )
            control = input
            control.name = 'string'
            Editor.config.subscribe(section, key, control, 
                func(value): 
                    var tmp_caret = control.caret_column
                    control.text = value
                    control.caret_column = tmp_caret
            )
            item.get_node('Control').add_child(control)
    
    # 在控件被移除时取消订阅
    if control: 
        control.size_flags_vertical = 0
        control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        item.tree_exiting.connect(
            func(): Editor.config.unsubscribe(section, key, control)
        )
    else:
        push_error('invalid control', section, key, current_value)

    return item

static func _setup_shortcut(button: Button, section: String, key: String) -> void:
    # 创建一个临时的KeyCapture节点
    var key_capture = KeyCapture.new()
    button.get_tree().root.add_child(key_capture)
    
    key_capture.show_key_capture()
    var captured_key = await key_capture.key_captured
    
    if captured_key:
        button.text = Editor.config.get_key_shown(captured_key)
        Editor.config.set_setting(section, key, captured_key)

    button.release_focus()
    key_capture.queue_free()

static func _setup_directory(button: Button, section: String, key: String):
    var doc_man = Editor.view.core.document_manager
    doc_man.show_directory_dialog()
    var file_path = await doc_man.file_selected
    if file_path:
        file_path = doc_man.get_home_folded(file_path)
        Editor.config.set_setting(section, key, file_path)
        button.text = file_path
        button.tooltip_text = file_path
    button.release_focus()

# ------------------------
static func build_sep(container: Control, pre_padding=0, post_padding=0):
    var rect = ColorRect.new()
    rect.name = 'Sep'
    rect.custom_minimum_size = Vector2(10,1)
    rect.color = '2a2a2a'
    if pre_padding or post_padding:
        var con = VBoxContainer.new()
        UI.set_separation(con, 0)
        if pre_padding:
            var pre_con = Control.new()
            pre_con.custom_minimum_size = Vector2(10, pre_padding)
            con.add_child(pre_con)
        con.add_child(rect)
        if post_padding:
            var post_con = Control.new()
            post_con.custom_minimum_size = Vector2(10, post_padding)
            con.add_child(post_con)
        container.add_child(con)
    else:
        container.add_child(rect)

static func build_rich(container: Control, content: String):
    var rich = RichTextLabel.new()
    rich.scroll_active = false
    rich.bbcode_enabled = true
    rich.context_menu_enabled = true
    rich.selection_enabled = true
    rich.drag_and_drop_selection_enabled = false
    rich.text = content
    rich.fit_content = true
    rich.custom_minimum_size = Vector2(100, 30)
    container.add_child(rich)
    return rich

static func build_btn(container: Control, text: String, callback=null):
    var box = HBoxContainer.new()
    box.alignment = 1
    var btn = Button.new()
    btn.text = text
    btn.custom_minimum_size = Vector2(100,30)
    btn.focus_mode = 0
    box.add_child(btn)
    container.add_child(box)
    if callback: btn.pressed.connect(callback)
    return btn

static func build_btn_right(container: Control, text: String, callback=null):
    var box = HBoxContainer.new()
    box.alignment = 2
    var btn = Button.new()
    btn.text = text
    btn.custom_minimum_size = Vector2(100,30)
    btn.focus_mode = 0
    box.add_child(btn)
    container.add_child(box)
    if callback: btn.pressed.connect(callback)
    return btn


static func build_control(container):
    var con = Control.new()
    con.size_flags_vertical = Control.SIZE_EXPAND_FILL
    con.custom_minimum_size = Vector2(100,10)
    container.add_child(con)
    return con

static func create_option(items=[], callback=null, default=0):
    var opt = OptionButton.new()
    for item in items:
        opt.add_item(str(item))
    if default >= 0 and default < items.size():
        opt.select(default)
    if callback: 
        opt.item_selected.connect(func(idx): 
            callback.call(idx)
        )
    return opt
