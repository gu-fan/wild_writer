class_name ConfigManager
extends Node

signal config_changed(section: String, key: String, value: Variant)

const CONFIG_FILE = "user://config.ini"
var config = ConfigFile.new()
var _has_valid_config = false

# 默认设置
var _default_settings = {
    "basic": {
        "auto_open_recent": 1,
        "auto_save": 1,
        "show_char_count": 1,
        "line_wrap": 1,
        "line_number": 1,
        "highlight_line": 1,
        "font_size": 1,
        "document_dir": "~/Documents",
        "recent_file": "",
        "backup_file": "",
        "backup_caret_line": 0,
        "backup_caret_col": 0,
    },
    "shortcut": {
        "new_file": "Ctrl+N",
        "open_file": "Ctrl+O",
        "save_file": "Ctrl+S",
        "open_setting": "Ctrl+Apostrophe",
        "switch_effect": "Ctrl+Slash",
        "split_view": "Ctrl+B",
    }
}

func _ready():
    load_config()

func load_config() -> void:
    # 尝试加载配置文件
    if config.load(CONFIG_FILE) == OK:
        _has_valid_config = true
    else:
        # 如果加载失败，使用默认设置
        _has_valid_config = false
        for section in _default_settings:
            for key in _default_settings[section]:
                set_setting(section, key, _default_settings[section][key])
        save_config()

func save_config() -> void:
    config.save(CONFIG_FILE)

func set_setting(section: String, key: String, value) -> void:
    if not _default_settings.has(section) or not _default_settings[section].has(key):
        push_warning("Invalid setting: %s/%s" % [section, key])
        return

    # 根据默认值的类型转换输入值
    var default_value = _default_settings[section][key]
    match typeof(default_value):
        TYPE_BOOL:
            value = bool(value)
        TYPE_INT:
            if typeof(value) == TYPE_BOOL:
                value = 1 if value else 0
            else:
                value = int(value)
        TYPE_FLOAT:
            if typeof(value) == TYPE_BOOL:
                value = 1.0 if value else 0.0
            else:
                value = float(value)
        TYPE_STRING:
            value = str(value)
    
    config.set_value(section, key, value)
    save_config()
    emit_signal("config_changed", section, key, value)

func set_setting_no_signal(section: String, key: String, value) -> void:
    if not _default_settings.has(section) or not _default_settings[section].has(key):
        push_warning("Invalid setting: %s/%s" % [section, key])
        return
        
    config.set_value(section, key, value)
    save_config()

func get_setting(section: String, key: String):
    if not _default_settings.has(section) or not _default_settings[section].has(key):
        push_warning("Invalid setting: %s/%s" % [section, key])
        return null
        
    var default_value = _default_settings[section][key]
    if _has_valid_config and config.has_section_key(section, key):
        var value = config.get_value(section, key)
        # 根据默认值的类型转换配置值
        match typeof(default_value):
            TYPE_BOOL:
                return bool(value)
            TYPE_INT:
                return int(value)
            TYPE_FLOAT:
                return float(value)
            TYPE_STRING:
                return str(value)
            _:
                return value
    return default_value

func get_section_settings(section: String) -> Dictionary:
    if not _default_settings.has(section):
        return {}
    
    var settings = {}
    for key in _default_settings[section]:
        settings[key] = get_setting(section, key)
    return settings

# 便捷方法
func get_basic_setting(key: String):
    return get_setting("basic", key)

func set_basic_setting(key: String, value) -> void:
    set_setting("basic", key, value)
