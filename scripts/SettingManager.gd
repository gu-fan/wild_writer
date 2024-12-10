extends Node
# class_name SettingManager
# Now in global SettingManager

signal setting_changed

# ~/.local/share/godot/app_userdata/wild_writer/wild_writer.ini
const SETTINGS_FILE: String = "user://wild_writer.ini"
# backup current editing file
const BACKUP_FILE: String = "user://backup.txt"
var config: ConfigFile = ConfigFile.new()

var _has_valid_config = false
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
        "open_setting": "Ctrl+Apostrophe"
    },
    "effect": {
        "level": 1,
        "combo": 1,
        "combo_shot": 1,
        "audio": 1,
        "screen_shake": 1,
        "char_effect": 1,
        "char_particle": 1,
        "enter_effect": 1,
        "delete_effect":1 
    },
    "ime": {
        "show_icon": 1,
        "page_size": 5,
        "switch_key": "Shift+Escape",
        "prev_page_key": "BracketLeft",
        "next_page_key": "BracketRight"
    },
}

const KEY_DISPLAY_MAP = {
    "apostrophe": "'",
    "backslash": "\\",
    "slash": "/",
    "semicolon": ";",
    "comma": ",",
    "period": ".",
    "minus": "-",
    "equal": "=",
    "bracketleft": "[",
    "bracketright": "]",
    "quoteleft": "`",
    "space": "Space",
    "escape": "Esc",
    "tab": "Tab",
    "return": "Enter",
    "backspace": "←",
    "delete": "Delete",
    "insert": "Insert",
    "home": "Home",
    "end": "End",
    "pageup": "PgUp",
    "pagedown": "PgDn",
    "up": "↑",
    "down": "↓",
    "left": "←",
    "right": "→",
    "shift+apostrophe": "\"",
    "shift+backslash": "|",
    "shift+slash": "?",
    "shift+semicolon": ":",
    "shift+comma": "<",
    "shift+period": ">",
    "shift+space": "_",
    "shift+minus": "_",
    "shift+equal": "+",
    "shift+bracketleft": "{",
    "shift+bracketright": "}",
    "shift+quoteleft": "~",
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
        TYPE_VECTOR2:
            if not value is Vector2:
                value = Vector2(value)
        TYPE_COLOR:
            if not value is Color:
                value = Color(value)
    
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
            TYPE_VECTOR2:
                if value is Vector2:
                    return value
                return Vector2(value)
            TYPE_COLOR:
                if value is Color:
                    return value
                return Color(value)
            _:
                return value
    return default_value

# 重置所有设置到默认值
func reset_to_default():
    for section in _default_settings:
        if section == 'shortcut': continue
        for key in _default_settings[section]:
            set_setting(section, key, _default_settings[section][key])
    save_settings()

func reset_key_to_default():
    for key in _default_settings['shortcut']:
        set_setting('shortcut', key, _default_settings['shortcut'][key])
    save_settings()

# 获取某个分类的所有设置
func get_section_settings(section: String) -> Dictionary:
    if not _default_settings.has(section):
        return {}
    
    var settings = {}
    for key in _default_settings[section]:
        settings[key] = get_setting(section, key)
    return settings

func get_basic_setting(key: String):
    return get_setting("basic", key)

func set_basic_setting(key: String, value) -> void:
    set_setting("basic", key, value)

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

func set_recent(value) -> void:
    set_setting_no_signal('basic', 'recent_file', value)
func set_backup(value) -> void:
    set_setting_no_signal('basic', 'backup_file', value)

# ---------------------------
static func get_key_shown(key_string: String) -> String:
    if key_string.is_empty():
        return ""
        
    var parts = key_string.split("+")
    var result = []
    
    for part in parts:
        # 处理修饰键
        match part.to_lower():
            "ctrl":
                result.append("Ctrl")
            "shift":
                result.append("Shift")
            "alt":
                result.append("Alt")
            "meta", "cmd", "command", "super":
                result.append("Cmd")
            _:
                # 查找映射表中的显示名称
                # var p_c = part.capitalize()
                var p_l = part.to_lower()
                if SettingManager.KEY_DISPLAY_MAP.has(p_l):
                    result.append(SettingManager.KEY_DISPLAY_MAP[p_l])
                else:
                    result.append(part)
    
    return "+".join(result)
static func get_key_shown_shift(key_string: String) -> String:
    if key_string.is_empty():
        return ""
        
    var parts = key_string.split("+")
    var result = []
    
    var has_shift = false
    for part in parts:
        # 处理修饰键
        match part.to_lower():
            "ctrl":
                result.append("Ctrl")
            "shift":
                has_shift = true
            "alt":
                result.append("Alt")
            "meta", "cmd", "command", "super":
                result.append("Cmd")
            _:
                # 查找映射表中的显示名称
                var p_l = part.to_lower()
                if has_shift: p_l = 'shift+' + p_l
                if SettingManager.KEY_DISPLAY_MAP.has(p_l):
                    result.append(SettingManager.KEY_DISPLAY_MAP[p_l])
                else:
                    if has_shift:
                        result.append(part)
                    else:
                        result.append(p_l)
    
    return "+".join(result)

func is_match_shortcut(k: String, sec: String, key: String) -> bool:
    if k.is_empty():
        return false
    
    # Get the configured shortcut from settings
    var shortcut = get_setting(sec, key)
    if shortcut == null:
        return false
    
    # Convert both strings to lowercase for case-insensitive comparison
    return k.to_lower() == shortcut.to_lower()

func is_match_key(k: String, key: String) -> bool:
    if k.is_empty(): return false
    if key.is_empty(): return false
    return k.to_lower() == key.to_lower()
