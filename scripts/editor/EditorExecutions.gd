class_name EditorExecutions
extends RefCounted

var editor_view: Node  # Reference to EditorView instance

var available_executors = {
    "setting": {
        "description": "setting",
        "executor": "setting"
    },
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
        "setting":
            toggle_setting(args)
    
# 执行器实现
func execute_python(args: Dictionary) -> void:
    # Get the current text from the editor
    var code = last_focused_editor.get_selected_text()
    if code.is_empty():
        code = last_focused_editor.text
    
    # Create a temporary Python file
    var temp_dir = OS.get_user_data_dir()
    var temp_file = temp_dir.path_join("temp_script.py")
    var output_file = temp_dir.path_join("output.txt")
    
    # Write the code to the temp file
    var file = FileAccess.open(temp_file, FileAccess.WRITE)
    if file:
        file.store_string(code)
        file.close()
    
    # Build the Python command
    var python_cmd = ""
    if OS.has_feature("windows"):
        python_cmd = "python"
    else:
        python_cmd = "python3"
    
    # Create process to run the command
    var output = []
    var exit_code = OS.execute(python_cmd, [temp_file], output, true)
    
    # Log the output
    if not output.is_empty():
        editor_view.logging("Python output: ")
        output = output[0].split('\n')
        for line in output:
            if not line.strip_edges().is_empty():
                editor_view.logging(line.strip_edges())
    
    # Clean up temporary files
    if FileAccess.file_exists(temp_file):
        DirAccess.remove_absolute(temp_file)
    
    # Log execution status
    if exit_code == 0:
        editor_view.logging("Python script executed successfully")
    else:
        editor_view.logging("Python script failed with exit code: " + str(exit_code))

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

func toggle_setting(args:Dictionary):
    editor_view.toggle_setting()
