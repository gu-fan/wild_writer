class_name ConfigManager
extends Node

signal setting_changed(section: String, key: String, value: Variant)

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
    },
    "network": {
        "default_port": 7000,
        "default_host": "127.0.0.1",
        "auto_accept_duel": false,
        "show_typing_stats": true
    }
}

var _subscriptions = {}  # 添加到类的成员变量

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

func save_config() -> void:
    config.save(CONFIG_FILE)

func set_setting(section: String, key: String, value) -> void:
    print("Setting config: %s/%s = %s" % [section, key, value])
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
    
    print("After conversion: %s/%s = %s" % [section, key, value])
    config.set_value(section, key, value)
    save_config()
    emit_signal("setting_changed", section, key, value)

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

# Network settings convenience methods
func get_network_setting(key: String):
    return get_setting("network", key)

func set_network_setting(key: String, value) -> void:
    set_setting("network", key, value)


# --------------------------------
# build ui               # config -> ui
# ui binding to config   # ui change -> config change -> save
# update ui by config     # config -> ui
# update editor by config # config -> editor

const SETTINGS_CONFIG = {
    "basic": {
        "auto_open_recent": {
            "type": "bool",
            "default": true,
            "label": "AUTO_OPEN_RECENT"
        },
        "auto_save": {
            "type": "bool",
            "default": true,
            "label": "AUTO_SAVE"
        },
        "show_char_count": {
            "type": "bool",
            "default": true,
            "label": "SHOW_CHAR_COUNT"
        },
        "line_wrap": {
            "type": "bool",
            "default": true,
            "label": "LINE_WRAP"
        },
        "font_size": {
            "type": "int",
            "default": 1,
            "min": 0,
            "max": 3,
            "label": "FONT_SIZE"
        },
    },
    "ime": {
        "shuangpin": {
            "type": "bool",
            "default": false,
            "label": "启用双拼"
        },
        "fuzzy": {
            "type": "bool",
            "default": false,
            "label": "启用模糊音"
        },
    },
}

func build_ui():
    var settings = Editor.init_node('ui/settings:Settings')
    # 获取设置界面的容器节点
    var basic_container = settings.get_node("Margin/Background/TabContainer/TAB_BASIC/Margin/VBox")
    
    if basic_container:
        SettingsBuilder.build_settings(basic_container, SETTINGS_CONFIG, "basic")

func init_config(section: String, key: String, object:Object, callback: Callable) -> void:
    var current_value = get_setting(section, key)
    callback.call(current_value)

func subscribe(section: String, key: String, object:Object, callback: Callable) -> void:
    var wrapper = func(s, k, v):
        if section == s and key == k:
            callback.call(v)
    
    # 存储订阅信息
    var sub_key = "%s/%s/%s" % [section, key, object.get_instance_id()]
    _subscriptions[sub_key] = wrapper
    setting_changed.connect(wrapper)

func unsubscribe(section: String, key: String, object: Object) -> void:
    # 构建订阅键
    var sub_key = "%s/%s/%s" % [section, key, object.get_instance_id()]
    
    # 检查并移除订阅
    if _subscriptions.has(sub_key):
        setting_changed.disconnect(_subscriptions[sub_key])
        _subscriptions.erase(sub_key)
