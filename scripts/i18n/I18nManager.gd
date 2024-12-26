class_name I18nManager
extends Node

signal locale_changed(locale: String)

const TRANSLATIONS_PATH = "res://resources/translations/"
const USER_TRANSLATIONS_PATH = "user://translations/"
const DEFAULT_LOCALE = "en"

var current_locale: String = DEFAULT_LOCALE
var translations: Dictionary = {}
var fallback_translations: Dictionary = {}

var editor_core
func _ready() -> void:
    _init_translations()
    editor_core = get_parent()
    # 从配置中加载语言设置（如果有ConfigManager）
    if editor_core.has_node("ConfigManager"):
        var config = editor_core.get_node("ConfigManager")
        var saved_locale = config.get_basic_setting("locale", DEFAULT_LOCALE)
        change_locale(saved_locale)

func _init_translations() -> void:
    # 加载内置翻译
    _load_translations_from_dir(TRANSLATIONS_PATH)
    
    # 加载用户自定义翻译
    _load_translations_from_dir(USER_TRANSLATIONS_PATH)
    
    # 设置后备翻译
    if translations.has(DEFAULT_LOCALE):
        fallback_translations = translations[DEFAULT_LOCALE]

func _load_translations_from_dir(path: String) -> void:
    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".json"):
                var locale = file_name.replace(".json", "")
                var trans = _load_translation_file(path + file_name)
                if trans:
                    if translations.has(locale):
                        translations[locale].merge(trans)
                    else:
                        translations[locale] = trans
            file_name = dir.get_next()

func _load_translation_file(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
        
    var file = FileAccess.open(path, FileAccess.READ)
    var json = JSON.parse_string(file.get_as_text())
    return json if json is Dictionary else {}

# 公共API

# 改变当前语言
func change_locale(locale: String) -> void:
    if not translations.has(locale):
        push_warning("Locale not found: %s, falling back to %s" % [locale, DEFAULT_LOCALE])
        locale = DEFAULT_LOCALE
    
    current_locale = locale
    
    # 保存到配置（如果有ConfigManager）
    if editor_core.has_node("ConfigManager"):
        var config = editor_core.get_node("ConfigManager")
        config.set_basic_setting("locale", locale)
    
    emit_signal("locale_changed", locale)

# 获取翻译文本
func translate(key: String, params: Dictionary = {}) -> String:
    var text = ""
    
    # 尝试从当前语言获取
    if translations.has(current_locale):
        text = translations[current_locale].get(key, "")
    
    # 如果没找到，使用后备翻译
    if text.is_empty():
        text = fallback_translations.get(key, key)
    
    # 替换参数
    for param_key in params:
        text = text.replace("{" + param_key + "}", str(params[param_key]))
    
    return text

# 获取所有可用的语言
func get_available_locales() -> Array:
    return translations.keys()

# 获取当前语言
func get_current_locale() -> String:
    return current_locale

# 添加或更新翻译
func add_translation(locale: String, translations_data: Dictionary) -> void:
    if translations.has(locale):
        translations[locale].merge(translations_data)
    else:
        translations[locale] = translations_data
    
    # 如果是默认语言，更新后备翻译
    if locale == DEFAULT_LOCALE:
        fallback_translations = translations[locale]

# 保存用户自定义翻译
func save_user_translation(locale: String) -> void:
    if not translations.has(locale):
        return
        
    var path = USER_TRANSLATIONS_PATH + locale + ".json"
    var file = FileAccess.open(path, FileAccess.WRITE)
    var json = JSON.stringify(translations[locale])
    file.store_string(json) 
