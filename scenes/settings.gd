extends Control

# 基本设置相关节点
@onready var auto_open_recent = $TabBar/BASIC/Margin/VBox/AutoOpen/CheckButton
@onready var auto_save = $TabBar/BASIC/Margin/VBox/AutoSave/CheckButton
@onready var show_char_count = $TabBar/BASIC/Margin/VBox/CharCount/CheckButton
@onready var line_wrap = $TabBar/BASIC/Margin/VBox/WrapLine/CheckButton
@onready var line_number = $TabBar/BASIC/Margin/VBox/LineNumber/CheckButton
@onready var font_size_slider = $TabBar/BASIC/Margin/VBox/FontSize/HSlider
@onready var font_size_label = $TabBar/BASIC/Margin/VBox/FontSize/Label
@onready var highlight_line = $TabBar/BASIC/Margin/VBox/HighlightLine/CheckButton
@onready var document_dir = $TabBar/BASIC/Margin/VBox/DocumentDir/Button

# 快捷键设置相关节点
@onready var new_file_key = $TabBar/KEY/Margin/VBox/NewFile/Button
@onready var open_file_key = $TabBar/KEY/Margin/VBox/OpenFile/Button
@onready var save_file_key = $TabBar/KEY/Margin/VBox/SaveFile/Button
@onready var open_setting_key = $TabBar/KEY/Margin/VBox/OpenSetting/Button

# 特效设置相关节点
@onready var effect_level = $TabBar/EFFECT/Margin/VBox/Level/Control/CheckButton
@onready var effect_mask = $TabBar/EFFECT/Margin/VBox/EndSep/ColorRect
@onready var combo_effect = $TabBar/EFFECT/Margin/VBox/Combo/CheckButton
@onready var combo_shot = $TabBar/EFFECT/Margin/VBox/ComboShot/CheckButton
@onready var audio = $TabBar/EFFECT/Margin/VBox/Audio/CheckButton
@onready var screen_shake = $TabBar/EFFECT/Margin/VBox/ScreenShake/CheckButton
@onready var char_effect = $TabBar/EFFECT/Margin/VBox/CharEffect/CheckButton
@onready var enter_effect = $TabBar/EFFECT/Margin/VBox/EnterEffect/CheckButton
@onready var delete_effect = $TabBar/EFFECT/Margin/VBox/DeleteEffect/CheckButton

# 输入法设置相关节点
@onready var bottom_icon = $TabBar/INPUT/Margin/VBox/bottom_icon/CheckButton
@onready var page_size = $TabBar/INPUT/Margin/VBox/PageSize/LineEdit
@onready var switch_key = $TabBar/INPUT/Margin/VBox/SwitchKey/LineEdit
@onready var prev_page_key = $TabBar/INPUT/Margin/VBox/PrevPage/LineEdit
@onready var next_page_key = $TabBar/INPUT/Margin/VBox/NextPage/LineEdit

@onready var reset = $TabBar/BASIC/Margin/VBox/Reset/Button
@onready var reset_key = $TabBar/KEY/Margin/VBox/Reset/Button

var editor_main

var key_capture: KeyCapture 


func _ready():

    editor_main = get_tree().current_scene

    key_capture = KeyCapture.new()
    add_child(key_capture)

    # 连接基本设置信号
    auto_open_recent.toggled.connect(_on_auto_open_recent_toggled)
    auto_save.toggled.connect(_on_auto_save_toggled)
    show_char_count.toggled.connect(_on_show_char_count_toggled)
    line_wrap.toggled.connect(_on_line_wrap_toggled)
    line_number.toggled.connect(_on_line_number_toggled)
    highlight_line.toggled.connect(_on_highlight_line_toggled)
    font_size_slider.value_changed.connect(_on_font_size_changed)
    reset.pressed.connect(_on_reset_pressed)

    document_dir.pressed.connect(_on_document_dir_pressed)
    
    # 连接快捷键设置信号
    new_file_key.pressed.connect(_on_new_file_pressed)
    open_file_key.pressed.connect(_on_open_file_pressed)
    save_file_key.pressed.connect(_on_save_file_pressed)
    open_setting_key.pressed.connect(_on_open_setting_pressed)

    reset_key.pressed.connect(_on_reset_key_pressed)
    
    # 连接特效设置信号
    effect_level.toggled.connect(_on_effect_level_toggled)
    combo_effect.toggled.connect(_on_combo_effect_toggled)
    combo_shot.toggled.connect(_on_combo_shot_toggled)
    audio.toggled.connect(_on_audio_toggled)
    screen_shake.toggled.connect(_on_screen_shake_toggled)
    char_effect.toggled.connect(_on_char_effect_toggled)
    enter_effect.toggled.connect(_on_enter_effect_toggled)
    delete_effect.toggled.connect(_on_delete_effect_toggled)
    
    # 连接输入法设置信号
    bottom_icon.toggled.connect(_on_bottom_icon_toggled)
    page_size.value_changed.connect(_on_page_size_changed)
    switch_key.text_changed.connect(_on_switch_key_changed)
    prev_page_key.text_changed.connect(_on_prev_page_key_changed)
    next_page_key.text_changed.connect(_on_next_page_key_changed)
    
    # 加载当前设置
    load_current_settings()


func load_current_settings():
    # 加载基本设置
    auto_open_recent.button_pressed = SettingManager.get_setting("basic", "auto_open_recent")
    auto_save.button_pressed = SettingManager.get_setting("basic", "auto_save")
    show_char_count.button_pressed = SettingManager.get_setting("basic", "show_char_count")
    line_wrap.button_pressed = SettingManager.get_setting("basic", "line_wrap")
    line_number.button_pressed = SettingManager.get_setting("basic", "line_number")
    font_size_slider.value = SettingManager.get_setting("basic", "font_size")
    font_size_label.text = _get_font_size_label(font_size_slider.value)
    highlight_line.button_pressed =  SettingManager.get_setting("basic", "highlight_line")
    document_dir.text =  SettingManager.get_setting("basic", "document_dir")
    document_dir.tooltip_text = document_dir.text
    
    # 加载快捷键
    new_file_key.text = _get_key_shown(SettingManager.get_setting("shortcut", "new_file"))
    open_file_key.text = _get_key_shown(SettingManager.get_setting("shortcut", "open_file"))
    save_file_key.text = _get_key_shown(SettingManager.get_setting("shortcut", "save_file"))
    open_setting_key.text = _get_key_shown(SettingManager.get_setting("shortcut", "open_setting"))

    # 加载特效设置
    effect_level.button_pressed = SettingManager.get_setting("effect", "level")
    effect_mask.visible = !effect_level.button_pressed


    combo_effect.button_pressed = SettingManager.get_setting("effect", "combo")
    combo_shot.button_pressed = SettingManager.get_setting("effect", "combo_shot")
    audio.button_pressed = SettingManager.get_setting("effect", "audio")
    screen_shake.button_pressed = SettingManager.get_setting("effect", "screen_shake")
    char_effect.button_pressed = SettingManager.get_setting("effect", "char_effect")
    enter_effect.button_pressed = SettingManager.get_setting("effect", "enter_effect")
    delete_effect.button_pressed = SettingManager.get_setting("effect", "delete_effect")
    
    # 加载输入法设置
    bottom_icon.button_pressed = SettingManager.get_ime_setting("show_icon")
    page_size.value = SettingManager.get_ime_setting("page_size")
    switch_key.text = SettingManager.get_ime_setting("switch_key")
    prev_page_key.text = SettingManager.get_ime_setting("prev_page_key")
    next_page_key.text = SettingManager.get_ime_setting("next_page_key")

# IME设置回调
func _on_ime_icon_toggled(button_pressed: bool):
    SettingManager.set_ime_setting("show_icon", button_pressed)

func _on_page_size_changed(value: float):
    SettingManager.set_ime_setting("page_size", int(value))

# 基本设置回调
func _get_font_size_label(v: int):
    var t = ''
    match v:
        0: t = '字体大小   小' 
        1: t = '字体大小   中' 
        2: t = '字体大小   大' 
        3: t = '字体大小   超大' 
    return t

func _on_font_size_changed(value: float):
    SettingManager.set_basic_setting("font_size", value)
    font_size_label.text = _get_font_size_label(font_size_slider.value)

# 快捷键设置
func _on_switch_key_changed(new_text: String):
    SettingManager.set_ime_setting("switch_key", new_text)

func _on_prev_page_key_changed(new_text: String):
    SettingManager.set_ime_setting("prev_page_key", new_text)

func _on_next_page_key_changed(new_text: String):
    SettingManager.set_ime_setting("next_page_key", new_text)

# 基本设置回调
func _on_auto_open_recent_toggled(button_pressed: bool):
    SettingManager.set_setting("basic", "auto_open_recent", button_pressed)

func _on_auto_save_toggled(button_pressed: bool):
    SettingManager.set_setting("basic", "auto_save", button_pressed)

func _on_show_char_count_toggled(button_pressed: bool):
    SettingManager.set_setting("basic", "show_char_count", button_pressed)

func _on_line_wrap_toggled(button_pressed: bool):
    SettingManager.set_setting("basic", "line_wrap", button_pressed)
func _on_line_number_toggled(button_pressed: bool):
    SettingManager.set_setting("basic", "line_number", button_pressed)
func _on_highlight_line_toggled(button_pressed: bool):
    SettingManager.set_setting("basic", "highlight_line", button_pressed)

# 重置所有设置
func _on_reset_pressed():
    SettingManager.reset_to_default()
    load_current_settings()
func _on_reset_key_pressed():
    SettingManager.reset_key_to_default()
    load_current_settings()

# 快捷键设置回调
func _on_new_file_pressed():
    key_capture.show_key_capture()
    var key = await key_capture.key_captured
    if key:
        new_file_key.text = _get_key_shown(key)
        SettingManager.set_setting("shortcut", "new_file", key)
    new_file_key.release_focus()

func _on_open_file_pressed():
    key_capture.show_key_capture()
    var key = await key_capture.key_captured
    if key:
        open_file_key.text = _get_key_shown(key)
        SettingManager.set_setting("shortcut", "open_file", key)
    open_file_key.release_focus()

func _on_save_file_pressed():
    key_capture.show_key_capture()
    var key = await key_capture.key_captured
    if key:
        save_file_key.text = _get_key_shown(key)
        SettingManager.set_setting("shortcut", "save_file", key)
    save_file_key.release_focus()

func _on_open_setting_pressed():
    key_capture.show_key_capture()
    var key = await key_capture.key_captured
    if key:
        open_setting_key.text = _get_key_shown(key)
        SettingManager.set_setting("shortcut", "open_setting", key)
    open_setting_key.release_focus()

func _get_key_shown(key):
    return SettingManager.get_key_shown(key)

# 特效设置回调
func _on_effect_level_toggled(button_pressed: bool):
    SettingManager.set_setting("effect", "level", button_pressed)
    effect_mask.visible = !button_pressed

func _on_combo_effect_toggled(button_pressed: bool):
    SettingManager.set_setting("effect", "combo", button_pressed)
func _on_combo_shot_toggled(button_pressed: bool):
    SettingManager.set_setting("effect", "combo_shot", button_pressed)

func _on_audio_toggled(button_pressed: bool):
    SettingManager.set_setting("effect", "audio", button_pressed)

func _on_screen_shake_toggled(button_pressed: bool):
    SettingManager.set_setting("effect", "screen_shake", button_pressed)

func _on_char_effect_toggled(button_pressed: bool):
    SettingManager.set_setting("effect", "char_effect", button_pressed)

func _on_enter_effect_toggled(button_pressed: bool):
    SettingManager.set_setting("effect", "enter_effect", button_pressed)

func _on_delete_effect_toggled(button_pressed: bool):
    SettingManager.set_setting("effect", "delete_effect", button_pressed)

# 输入法设置回调
func _on_bottom_icon_toggled(button_pressed: bool):
    SettingManager.set_ime_setting("show_icon", button_pressed)

func _on_document_dir_pressed():
    editor_main.file_manager.show_directory_dialog()
    var file_path = await editor_main.file_manager.file_selected
    if file_path:
        file_path = file_path.replace(OS.get_environment("HOME"), "~")
        SettingManager.set_basic_setting("document_dir", file_path)
        document_dir.text =  file_path
        document_dir.tooltip_text = document_dir.text
