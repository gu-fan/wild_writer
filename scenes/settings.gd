extends Control

# 基本设置相关节点
@onready var auto_open_recent = $TabBar/BASIC/Margin/VBox/AutoOpen/CheckButton
@onready var auto_save = $TabBar/BASIC/Margin/VBox/AutoSave/CheckButton
@onready var show_char_count = $TabBar/BASIC/Margin/VBox/CharCount/CheckButton
@onready var word_wrap = $TabBar/BASIC/Margin/VBox/WrapLine/CheckButton
@onready var font_size_slider = $TabBar/BASIC/Margin/VBox/FontSize/HSlider

# 快捷键设置相关节点
@onready var new_file_key = $TabBar/BASIC/Margin/VBox/NewFile/LineEdit
@onready var open_file_key = $TabBar/BASIC/Margin/VBox/OpenFile/LineEdit
@onready var save_file_key = $TabBar/BASIC/Margin/VBox/SaveFile/LineEdit
@onready var open_setting_key = $TabBar/BASIC/Margin/VBox/OpenSetting/LineEdit

# 特效设置相关节点
@onready var effect_level = $TabBar/EFFECT/Margin/VBox/Level/Control/HSlider
@onready var combo_effect = $TabBar/EFFECT/Margin/VBox/Combo/CheckButton
@onready var transparent = $TabBar/EFFECT/Margin/VBox/Transparent/CheckButton
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

func _ready():
    # 连接基本设置信号
    auto_open_recent.toggled.connect(_on_auto_open_recent_toggled)
    auto_save.toggled.connect(_on_auto_save_toggled)
    show_char_count.toggled.connect(_on_show_char_count_toggled)
    word_wrap.toggled.connect(_on_word_wrap_toggled)
    font_size_slider.value_changed.connect(_on_font_size_changed)

    reset.pressed.connect(_on_reset_pressed)
    
    # 连接快捷键设置信号
    new_file_key.text_changed.connect(_on_new_file_key_changed)
    open_file_key.text_changed.connect(_on_open_file_key_changed)
    save_file_key.text_changed.connect(_on_save_file_key_changed)
    open_setting_key.text_changed.connect(_on_open_setting_key_changed)
    
    # 连接特效设置信号
    effect_level.value_changed.connect(_on_effect_level_changed)
    combo_effect.toggled.connect(_on_combo_effect_toggled)
    transparent.toggled.connect(_on_transparent_toggled)
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
    word_wrap.button_pressed = SettingManager.get_setting("basic", "word_wrap")
    font_size_slider.value = SettingManager.get_setting("basic", "font_size") / 16.0
    
    # 加载快捷键
    new_file_key.text = SettingManager.get_setting("shortcut", "new_file")
    open_file_key.text = SettingManager.get_setting("shortcut", "open_file")
    save_file_key.text = SettingManager.get_setting("shortcut", "save_file")
    open_setting_key.text = SettingManager.get_setting("shortcut", "open_setting")
    
    # 加载特效设置
    effect_level.value = SettingManager.get_setting("effect", "level")
    combo_effect.button_pressed = SettingManager.get_setting("effect", "combo")
    transparent.button_pressed = SettingManager.get_setting("effect", "transparent")
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
func _on_font_size_changed(value: float):
    var font_size = int(value * 16)  # 转换回实际字体大小
    SettingManager.set_basic_setting("font_size", font_size)

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

func _on_word_wrap_toggled(button_pressed: bool):
    SettingManager.set_setting("basic", "word_wrap", button_pressed)

# 重置所有设置
func _on_reset_pressed():
    SettingManager.reset_to_default()
    load_current_settings()

# 快捷键设置回调
func _on_new_file_key_changed(new_text: String):
    SettingManager.set_setting("shortcut", "new_file", new_text)

func _on_open_file_key_changed(new_text: String):
    SettingManager.set_setting("shortcut", "open_file", new_text)

func _on_save_file_key_changed(new_text: String):
    SettingManager.set_setting("shortcut", "save_file", new_text)

func _on_open_setting_key_changed(new_text: String):
    SettingManager.set_setting("shortcut", "open_setting", new_text)

# 特效设置回调
func _on_effect_level_changed(value: float):
    SettingManager.set_setting("effect", "level", value)

func _on_combo_effect_toggled(button_pressed: bool):
    SettingManager.set_setting("effect", "combo", button_pressed)

func _on_transparent_toggled(button_pressed: bool):
    SettingManager.set_setting("effect", "transparent", button_pressed)

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
