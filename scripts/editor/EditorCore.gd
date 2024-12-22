class_name EditorCore
extends Node

signal document_changed(doc: DocumentManager.Document)
signal editor_state_changed(state: Dictionary)
signal mod_loaded(mod_name: String)
signal mod_unloaded(mod_name: String)

var document_manager: DocumentManager
var command_manager: CommandManager
var key_system: KeySystem
var config_manager: ConfigManager
var mod_manager: ModManager
var network_manager: NetworkManager

func _ready():
    document_manager = DocumentManager.new()
    command_manager = CommandManager.new()
    key_system = KeySystem.new()
    config_manager = ConfigManager.new()
    mod_manager = ModManager.new()
    network_manager = NetworkManager.new()
    
    add_child(document_manager)
    add_child(command_manager)
    add_child(key_system)
    add_child(config_manager)
    add_child(mod_manager)
    add_child(network_manager)
    
    # 连接信号
    document_manager.document_changed.connect(
        func(doc): emit_signal("document_changed", doc)
    )
    
    # 加载配置
    config_manager.load_config()
    
    # 设置初始状态
    setup_initial_state()
    
    # Load mods after other systems are ready
    mod_manager.load_mods()

func setup_initial_state():
    # 应用配置
    var font_size = config_manager.get_basic_setting("font_size")
    emit_signal("editor_state_changed", {"key": "font_size", "value": font_size})
    
    var line_wrap = config_manager.get_basic_setting("line_wrap")
    emit_signal("editor_state_changed", {"key": "wrap_mode", "value": line_wrap})
    
    var highlight_line = config_manager.get_basic_setting("highlight_line")
    emit_signal("editor_state_changed", {"key": "highlight_line", "value": highlight_line})

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        key_system.handle_input(event)

# Add public API methods for mods to use
func register_command(command_name: String, callback: Callable) -> void:
    command_manager.register_command(command_name, callback)

func register_keybinding(key_combo: String, command_name: String) -> void:
    key_system.add_binding([key_combo], command_name)

func get_current_document() -> DocumentManager.Document:
    return document_manager.get_current_document()

func get_config(key: String):
    return config_manager.get_basic_setting(key)
