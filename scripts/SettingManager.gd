extends Node
# class_name SettingManager
# Now in global SettingManager

signal setting_changed

# ~/.local/share/godot/app_userdata/wild_writer/wild_writer.ini
const SETTINGS_FILE: String = "user://wild_writer.ini"
var config: ConfigFile = ConfigFile.new()

var _has_valid_config = false
var _default_settings = {
     "basic": {
        "auto_open_recent": true,
        "recent_file": "",
        "auto_save": true,
        "show_char_count": true,
        "word_wrap": true,
        "font_size": 16
    },
    "shortcut": {
        "new_file": "Ctrl+N",
        "open_file": "Ctrl+O",
        "save_file": "Ctrl+S",
        "open_setting": "Ctrl+'"
    },
    "effect": {
        "level": 1.0,
        "combo": true,
        "transparent": false,
        "audio": true,
        "screen_shake": true,
        "char_effect": true,
        "enter_effect": true,
        "delete_effect": true
    },
    "ime": {
        "show_icon": true,
        "page_size": 5,
        "switch_key": "Shift+Space",
        "prev_page_key": "[",
        "next_page_key": "]"
    },
}

func _ready():
    load_settings()

func load_settings():
    # 尝试加载配置文件
    if config.load(SETTINGS_FILE) == OK:
        _has_valid_config = true
    else:
        # 如果加载失败，使用默认设置
        _has_valid_config = false
        for section in _default_settings:
            for key in _default_settings[section]:
                set_setting(section, key, _default_settings[section][key])
        save_settings()

func save_settings():
    config.save(SETTINGS_FILE)

func set_setting(section: String, key: String, value) -> void:
    if not _default_settings.has(section) or not _default_settings[section].has(key):
        push_warning("Invalid setting: %s/%s" % [section, key])
        return
        
    config.set_value(section, key, value)
    save_settings()

    emit_signal('setting_changed')

func set_setting_no_signal(section: String, key: String, value) -> void:
    if not _default_settings.has(section) or not _default_settings[section].has(key):
        push_warning("Invalid setting: %s/%s" % [section, key])
        return
        
    config.set_value(section, key, value)
    save_settings()

func get_setting(section: String, key: String):
    if not _default_settings.has(section) or not _default_settings[section].has(key):
        push_warning("Invalid setting: %s/%s" % [section, key])
        return null
        
    if _has_valid_config and config.has_section_key(section, key):
        return config.get_value(section, key)
    return _default_settings[section][key]


func get_basic_setting(key: String):
    return get_setting("basic", key)

func set_basic_setting(key: String, value) -> void:
    set_setting("basic", key, value)


# 重置所有设置到默认值
func reset_to_default():
    for section in _default_settings:
        for key in _default_settings[section]:
            set_setting(section, key, _default_settings[section][key])
    save_settings()

# 获取某个分类的所有设置
func get_section_settings(section: String) -> Dictionary:
    if not _default_settings.has(section):
        return {}
    
    var settings = {}
    for key in _default_settings[section]:
        settings[key] = get_setting(section, key)
    return settings

# IME设置便捷方法
func get_ime_setting(key: String):
    return get_setting("ime", key)

func set_ime_setting(key: String, value) -> void:
    set_setting("ime", key, value)

# 效果设置便捷方法
func get_effect_setting(key: String):
    return get_setting("effect", key)

func set_effect_setting(key: String, value) -> void:
    set_setting("effect", key, value)

# 快捷键设置便捷方法
func get_shortcut_setting(key: String):
    return get_setting("shortcut", key)

func set_shortcut_setting(key: String, value) -> void:
    set_setting("shortcut", key, value)
