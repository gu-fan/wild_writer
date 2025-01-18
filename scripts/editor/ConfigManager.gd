class_name ConfigManager
extends Node

signal setting_changed(section: String, key: String, value: Variant)

const CONFIG_FILE = "user://config.ini"
var config = ConfigFile.new()
var _has_valid_config = false


# 默认设置
var _default_settings = {
    "basic": {
        "language": 0,
        "auto_open_recent": 1,
        "auto_save": 1,
        "show_char_count": 1,
        "line_wrap": 1,
        "line_number": 1,
        "highlight_line": 1,
        "document_dir": "~/Documents",
        "recent_file": "",
        "backup_file": "",
        "backup_caret_line": 0,
        "backup_caret_col": 0,
    },
    "interface":{
        "editor_font": 0,
        "effect_font": 1,
        "interface_font": 1,
        "font_size": 1,
        # "fullscreen": 0,
    },
    "effect": {
        "fx_switch": 1,
        "combo": 1,
        "combo_shot": 1,
        "audio": 1,
        # "screen_shake": 1,
        "screen_shake_level": 1,
        "char_effect": 1,
        "char_particle": 1,
        "char_sound": 0,
        "char_sound_increase": 1,
        "enter_effect": 1,
        "delete_effect":1 ,
        "match_effect":1 ,
        "match_words":"非常不错,我很开心,新年快乐,万事如意",
    },
    "shortcut": {
        "new_file": "Ctrl+N",
        "open_file": "Ctrl+O",
        "save_file": "Ctrl+S",
        "toggle_setting": "Ctrl+Apostrophe",
        "toggle_effect": "Ctrl+Slash",
        "toggle_ime": "Option+Escape",
        # "split_view": "Ctrl+B",
        "start_motion": "Ctrl+E",
        "start_command": "Ctrl+R",
    },
    "ime": {
        "pinyin_icon": 1,
        "shuangpin": 0,
        "pinyin_page_size": 5,
        # "switch_ime_key": "Shift+Escape",
        "prev_page_key": "BracketLeft",
        "next_page_key": "BracketRight",
        "fuzzy_pinyin": 0,
    },
    # "network": {
    #     "default_port": 7000,
    #     "default_host": "127.0.0.1",
    #     "auto_accept_duel": false,
    #     "show_typing_stats": true
    # }
}

const SETTINGS_CONFIG = {
    "basic": {
        "language": {
            "type": "option",
            "options": ["中文", "English"],
            "values": ["zh", "en"],
            "default": 0,
            "label": "LANGUAGE",
            "desc": ""
        },
        "auto_open_recent": {
            "type": "bool",
            "default": true,
            "label": "AUTO_OPEN_RECENT",
            "desc": "AUTO_OPEN_RECENT_DESC"
        },
        "auto_save": {
            "type": "bool",
            "default": true,
            "label": "AUTO_SAVE",
            "desc": "AUTO_SAVE_DESC"
        },
        "show_char_count": {
            "type": "bool",
            "default": true,
            "label": "SHOW_CHAR_COUNT",
            "desc": ""
        },
        "line_number": {
            "type": "bool",
            "default": true,
            "label": "LINE_NUMBER",
            "desc": ""
        },
        "highlight_line": {
            "type": "bool",
            "default": true,
            "label": "HIGHLIGHT_LINE",
            "desc": ""
        },
        "line_wrap": {
            "type": "bool",
            "default": true,
            "label": "LINE_WRAP",
            "desc": "LINE_WRAP_DESC"
        },
        "document_dir": {
            "type": "directory",
            "default": '~/Documents',
            "label": "DOCUMENT_DIR",
            "desc": "DOCUMENT_DIR_DESC"
        },
    },
    "shortcut": {
        "new_file": {
            "type": "shortcut",
            "default": "",
            "label": "NEW_FILE",
            "desc": ""
        },
        "open_file": {
            "type": "shortcut",
            "default": "",
            "label": "OPEN_FILE",
            "desc": ""
        },
        "save_file": {
            "type": "shortcut",
            "default": "",
            "label": "SAVE_FILE",
            "desc": ""
        },
        "toggle_setting": {
            "type": "shortcut",
            "default": "",
            "label": "TOGGLE_SETTING",
            "desc": "TOGGLE_SETTING_DESC"
        },
        "toggle_effect": {
            "type": "shortcut",
            "default": "",
            "label": "TOGGLE_EFFECT",
            "desc": ""
        },
        "toggle_ime": {
            "type": "shortcut",
            "default": "",
            "label": "TOGGLE_IME",
            "desc": "TOGGLE_IME_DESC"
        },
        "start_motion": {
            "type": "shortcut",
            "default": "",
            "label": "START_MOTION",
            "desc": "START_MOTION_DESC"
        },
        "start_command": {
            "type": "shortcut",
            "default": "",
            "label": "START_COMMAND",
            "desc": "START_COMMAND_DESC"
        },
    },
    "interface": {
        "editor_font": {
            "type": "option",
            "options": ["SANS_SERIF", "SERIF"],
            "values": ["NotoSansSC-Regular.ttf", "NotoSerifSC-SemiBold.ttf"],
            "default": 0,
            "label": "EDITOR_FONT",
            "desc": "EDITOR_FONT_DESC"
        },
        "font_size": {
            "type": "int",
            "default": 1,
            "min": 0,
            "max": 3,
            "label": "FONT_SIZE",
            "desc": "",
            "keys" : ["SMALL", "MIDDLE", "LARGE", "EXTRA_LARGE"],
            "values" : [16, 32, 48, 96],
        },
        "effect_font": {
            "type": "option",
            "options": ["YouSheBiaoTiHei", "MaoKenShiJinHei", "XiangCuiZeroHei"],
            "values": ["YouSheBiaoTiHei.ttf", "MaoKenShiJinHeiFix.tres", "XiangCuiZeroHeiFix.tres"],
            "default": 0,
            "label": "EFFECT_FONT",
            "desc": "EFFECT_FONT_DESC"
        },
        "interface_font": {
            "type": "option",
            "options": ["YouSheBiaoTiHei", "MaoKenShiJinHei", "XiangCuiZeroHei"],
            "values": ["YouSheBiaoTiHei.ttf", "MaoKenShiJinHeiFix.tres", "XiangCuiZeroHeiFix.tres"],
            "default": 0,
            "label": "INTERFACE_FONT",
            "desc": "INTERFACE_FONT_DESC"
        },
        # "fullscreen": {
        #     "type": "bool",
        #     "default": false,
        #     "label": "FULLSCREEN",
        #     "desc": "FULLSCREEN_DESC"
        # },
    },
    "effect": {
        "fx_switch": {
            "type": "bool",
            "default": true,
            "label": "FX_SWITCH",
            "desc": "",
        },
        "audio": {
            "type": "bool",
            "default": false,
            "label": "AUDIO",
            "desc": ""
        },
        "combo": {
            "type": "bool",
            "default": false,
            "label": "COMBO",
            "desc": "COMBO_DESC"
        },
        "combo_shot": {
            "type": "bool",
            "default": false,
            "label": "COMBO_SHOT",
            "desc": "COMBO_SHOT_DESC"
        },
        # "blip_fx_dir": {
        #     "type": "option",
        #     "default": false,
        #     "label": "AUDIO",
        #     "desc": "AUDIO_DESC"
        # },
        # "screen_shake": {
        #     "type": "bool",
        #     "default": false,
        #     "label": "SCREEN_SHAKE",
        #     "desc": "SCREEN_SHAKE_DESC"
        # },
        "screen_shake_level": {
            "type": "int",
            "default": 1,
            "min": 0,
            "max": 2,
            "label": "SCREEN_SHAKE_LEVEL",
            "desc": "SCREEN_SHAKE_LEVEL_DESC",
            "keys" : ["NONE", "SMALL", "LARGE"],
        },
        "char_effect": {
            "type": "bool",
            "default": false,
            "label": "CHAR_EFFECT",
            "desc": ""
        },
        "char_particle": {
            "type": "bool",
            "default": false,
            "label": "CHAR_PARTICLE",
            "desc": ""
        },
        "char_sound": {
            "type": "option",
            "options": ["CLICK", "TYPING", "WOOD", "GLASS"],
            "values": ["blip.wav", "click1.ogg", "drop_003.ogg", "glass_005.ogg"],
            "default": 0,
            "label": "CHAR_SOUND",
            "desc": ""
        },
        "char_sound_increase": {
            "type": "bool",
            "default": true,
            "label": "CHAR_SOUND_INCREASE",
            "desc": "CHAR_SOUND_INCREASE_DESC"
        },
        "enter_effect": {
            "type": "bool",
            "default": false,
            "label": "ENTER_EFFECT",
            "desc": ""
        },
        "delete_effect": {
            "type": "bool",
            "default": false,
            "label": "DELETE_EFFECT",
            "desc": ""
        },
        "match_effect": {
            "type": "bool",
            "default": false,
            "label": "MATCH_EFFECT",
            "desc": "MATCH_EFFECT_DESC"
        },
        "match_words": {
            "type": "string",
            "default": "",
            "placeholder": "match_PLACEHOLDER",
            "label": "MATCH_WORDS",
            "desc": ""
        },
    },
    "ime": {
        "pinyin_icon": {
            "type": "bool",
            "default": false,
            "label": "PINYIN_ICON",
            "desc": "PINYIN_ICON_DESC"
        },
        "shuangpin": {
            "type": "bool",
            "default": false,
            "label": "SHUANGPIN",
            "desc": "SHUANGPIN_DESC"
        },
        "fuzzy_pinyin": {
            "type": "bool",
            "default": false,
            "label": "FUZZY_PINYIN",
            "desc": "FUZZY_PINYIN_DESC"
        },
        "pinyin_page_size": {
            "type": "int",
            "default": 5,
            "label": "PINYIN_PAGE_SIZE",
            "desc": "PINYIN_PAGE_SIZE_DESC"
        },
        "prev_page_key": {
            "type": "shortcut",
            "default": "",
            "label": "PREV_PAGE_KEY",
            "desc": "PREV_PAGE_KEY_DESC"
        },
        "next_page_key": {
            "type": "shortcut",
            "default": "",
            "label": "NEXT_PAGE_KEY",
            "desc": "NEXT_PAGE_KEY_DESC"
        },
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

const RICH_TIPS = [
        'RICH_TIPS_0',
        'RICH_TIPS_1',
        'RICH_TIPS_2',
        'RICH_TIPS_3',
    ]

# ----------------
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
            "alt", "option":
                result.append("Alt")
            "meta", "cmd", "command", "super":
                result.append("Cmd")
            _:
                # 查找映射表中的��示名称
                # var p_c = part.capitalize()
                var p_l = part.to_lower()
                if KEY_DISPLAY_MAP.has(p_l):
                    result.append(KEY_DISPLAY_MAP[p_l])
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
            "alt", "option":
                result.append("Alt")
            "meta", "cmd", "command", "super":
                result.append("Cmd")
            _:
                # 查找映射表中的显示名称
                var p_l = part.to_lower()
                if has_shift: p_l = 'shift+' + p_l
                if KEY_DISPLAY_MAP.has(p_l):
                    result.append(KEY_DISPLAY_MAP[p_l])
                else:
                    if has_shift:
                        result.append(part)
                    else:
                        result.append(p_l)
    
    return "+".join(result)

func get_keys(section):
    return _default_settings[section].keys()
# ----------------

var _subscriptions = {}  # 添加到类的成员变量

func subscribe(section: String, key: String, object:Object, callback: Callable, is_init=false) -> void:
    var wrapper = func(s, k, v):
        if section == s and key == k:
            callback.call(v)
    
    # 存储订阅信息
    var sub_key = "%s/%s/%s" % [section, key, object.get_instance_id()]
    _subscriptions[sub_key] = wrapper
    setting_changed.connect(wrapper)

    if is_init:
        var current_value = get_setting(section, key)
        callback.call(current_value)

func unsubscribe(section: String, key: String, object: Object) -> void:
    # 构建订阅键
    var sub_key = "%s/%s/%s" % [section, key, object.get_instance_id()]
    
    # 检查并移除订阅
    if _subscriptions.has(sub_key):
        setting_changed.disconnect(_subscriptions[sub_key])
        _subscriptions.erase(sub_key)

func init_only(section, key, _object:Object, callback, _is_init=true):
    var current_value = get_setting(section, key)
    callback.call(current_value)
# ----------------
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

func get_effect_setting(key: String):
    return get_setting("effect", key)


func set_effect_setting(key: String, value) -> void:
    set_setting("effect", key, value)


func toggle_setting(section, key):
    var val = get_setting(section, key)
    set_setting(section, key, !val)
# --------------------------------
# build ui               # config -> ui
# ui binding to config   # ui change -> config change -> save
# update ui by config     # config -> ui
# update editor by config # config -> editor

var lb_rich_tips
func build_ui():
    var settings = Editor.init_node('ui/settings:Settings')
    settings.script = EditorConfigUI
    # 获取设置界面的容器节点
    var basic_container = settings.get_node("Margin/Background/TabContainer/TAB_BASIC/Scroll/Margin/VBox")
    
    if basic_container:
        SettingsBuilder.build_settings(basic_container, SETTINGS_CONFIG, "basic")
        SettingsBuilder.build_sep(basic_container, 0, 10)
        var tip = Rnd.pick(RICH_TIPS)
        lb_rich_tips = SettingsBuilder.build_rich(basic_container, tip)
        lb_rich_tips.size_flags_vertical =  Control.SIZE_EXPAND_FILL
        SettingsBuilder.build_sep(basic_container)
        SettingsBuilder.build_btn(basic_container, 'RESET_ALL', reset_to_default)

    var interface_container = settings.get_node("Margin/Background/TabContainer/TAB_INTERFACE/Scroll/Margin/VBox")
    if interface_container:
        SettingsBuilder.build_settings(interface_container, SETTINGS_CONFIG, "interface")
        SettingsBuilder.build_sep(interface_container)
        SettingsBuilder.build_control(interface_container)

    var effect_container = settings.get_node("Margin/Background/TabContainer/TAB_EFFECT/Scroll/Margin/VBox")
    if effect_container:
        SettingsBuilder.build_settings(effect_container, SETTINGS_CONFIG, "effect")
        SettingsBuilder.build_sep(effect_container)
        SettingsBuilder.build_control(effect_container)

    var shortcut_container = settings.get_node("Margin/Background/TabContainer/TAB_SHORTCUT/Scroll/Margin/VBox")
    if shortcut_container:
        SettingsBuilder.build_settings(shortcut_container, SETTINGS_CONFIG, "shortcut")
        SettingsBuilder.build_sep(shortcut_container, 5, 5)
        var lb_rich_shortcut = SettingsBuilder.build_rich(shortcut_container, 'SHORCUT_TIP')
        lb_rich_shortcut.size_flags_vertical =  Control.SIZE_EXPAND_FILL
        SettingsBuilder.build_sep(shortcut_container)
        SettingsBuilder.build_btn(shortcut_container, 'RESET_SHORTCUT', reset_key_to_default)

    var ime_container = settings.get_node("Margin/Background/TabContainer/TAB_IME/Scroll/Margin/VBox")
    if ime_container:
        SettingsBuilder.build_settings(ime_container, SETTINGS_CONFIG, "ime")
        SettingsBuilder.build_sep(ime_container)
        SettingsBuilder.build_control(ime_container)

    var about_container = settings.get_node("Margin/Background/TabContainer/TAB_ABOUT/Scroll/Margin/VBox")
    if about_container:
        # SettingsBuilder.build_settings(about_container, SETTINGS_CONFIG, "ime")
        # SettingsBuilder.build_sep(about_container)
        # SettingsBuilder.build_control(about_container)
        var rich
        rich = SettingsBuilder.build_rich(about_container, 'RICH_ABOUT_0')
        SettingsBuilder.build_sep(about_container)
        rich = SettingsBuilder.build_rich(about_container, 'RICH_ABOUT_1')
        rich.size_flags_vertical =  Control.SIZE_EXPAND_FILL

    settings.init()

# ----------------
func reset_to_default():
    for section in _default_settings:
        if section == 'shortcut': continue
        for key in _default_settings[section]:
            set_setting(section, key, _default_settings[section][key])
    save_config()

func reset_key_to_default():
    for key in _default_settings['shortcut']:
        set_setting('shortcut', key, _default_settings['shortcut'][key])
    save_config()
# ----------------
