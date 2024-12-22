class_name EditorExecutions
extends RefCounted

var editor_view: Node  # Reference to EditorView instance

var available_executors = {
    "python": {
        "description": "Run Python script",
        "executor": "python"
    },
    "node": {
        "description": "Run JavaScript with Node.js",
        "executor": "node"
    },
    "shell": {
        "description": "Execute shell command",
        "executor": "shell"
    },
    "host": {
        "description": "Host a game server",
        "executor": "host"
    },
    "join": {
        "description": "Join a game server",
        "executor": "join"
    },
    "duel": {
        "description": "Request a typing duel",
        "executor": "duel"
    }
}

var split_container: HSplitContainer
var primary_container: VBoxContainer
var secondary_container: VBoxContainer
var text_edit: CodeEdit
var text_edit_secondary: CodeEdit
var is_split_view: bool = false
var is_swapped_view: bool = false
var last_focused_editor: CodeEdit = null :
    set(v):
        editor_view.last_focused_editor = v
    get:
        return editor_view.last_focused_editor

func _init(_editor_view: Node) -> void:
    editor_view = _editor_view
    split_container = editor_view.split_container
    primary_container = editor_view.primary_container
    secondary_container = editor_view.secondary_container
    text_edit = editor_view.text_edit
    text_edit_secondary = editor_view.text_edit_secondary


func execute_command(command: String, args: Dictionary) -> void:
    print("Executing command:", command, "with args:", args)
    
    match command:
        "python":
            execute_python(args)
        "node":
            execute_node(args)
        "shell":
            execute_shell(args)
        "host":
            host_game(args)
        "join":
            join_game(args)
        "duel":
            request_duel(args)
    

# 执行器实现
func execute_python(args: Dictionary) -> void:
    # TODO: 实现 Python 代码执行
    pass

func execute_node(args: Dictionary) -> void:
    # TODO: 实现 Node.js 代码执行
    pass

func execute_shell(args: Dictionary) -> void:
    # TODO: 实现 Shell 命令执行
    pass

func host_game(args: Dictionary) -> void:
    var port = args.get("port", NetworkManager.DEFAULT_PORT)
    editor_view.core.network_manager.host_game(port)

func join_game(args: Dictionary) -> void:
    var address = args.get("address", "127.0.0.1")
    var port = args.get("port", NetworkManager.DEFAULT_PORT)
    editor_view.core.network_manager.join_game(address, port)

func request_duel(args: Dictionary) -> void:
    var peer_id = args.get("peer_id", 0)
    if peer_id > 0:
        editor_view.core.network_manager.send_duel_request(peer_id)
