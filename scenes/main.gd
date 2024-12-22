extends Node

var editor_view: EditorView

func _ready():
    editor_view = $CanvasLayer/EditorView
    
    # 加载配置
    editor_view.core.config_manager.load_config()
    
    # 设置初始状态
    setup_initial_state()

func setup_initial_state():
    # 处理命令行参数
    var args = OS.get_cmdline_args()
    if args.size() > 0:
        # 如果有命令行参数，打开指定文件
        editor_view.core.command_manager.execute_command(
            "open", 
            [args[0]]
        )
    else:
        pass

# ----------------------
