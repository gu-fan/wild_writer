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
        # 否则尝试打开上次编辑的文件
        # load_last_file()
        pass

func load_last_file():
    var config = editor_view.core.config_manager
    var auto_open_recent = config.get_basic_setting("auto_open_recent")
    if auto_open_recent:
        var recent_file = config.get_basic_setting("recent_file")
        var backup_file = config.get_basic_setting("backup_file")
        
        if recent_file:
            # 如果备份文件与最近文件相同，比较修改时间
            if backup_file == recent_file and FileAccess.file_exists(backup_file):
                var recent_time = FileAccess.get_modified_time(recent_file)
                var backup_time = FileAccess.get_modified_time(backup_file)
                
                if backup_time > recent_time:
                    # 备份文件更新，加载备份
                    editor_view.open_document_from_path(backup_file)
                    editor_view.current_file_path = recent_file  # 设置正确的文件路径
                    editor_view.status_bar.text = "Opened backup of " + recent_file
                    # 恢复光标位置
                    var backup_line = config.get_basic_setting("backup_caret_line")
                    var backup_col = config.get_basic_setting("backup_caret_col")
                    editor_view.text_edit.set_caret_line(backup_line)
                    editor_view.text_edit.set_caret_column(backup_col)
                else:
                    # 原文件更新，加载原文件
                    editor_view.open_document_from_path(recent_file)
            else:
                # 不同文件，直接加载最近文件
                editor_view.open_document_from_path(recent_file)
        elif FileAccess.file_exists(backup_file):
            # 没有最近文件，但有备份文件，加载备份
            editor_view.open_document_from_path(backup_file)
            editor_view.status_bar.text = "Opened last untitled"
            # 恢复光标位置
            var backup_line = config.get_basic_setting("backup_caret_line")
            var backup_col = config.get_basic_setting("backup_caret_col")
            editor_view.text_edit.set_caret_line(backup_line)
            editor_view.text_edit.set_caret_column(backup_col)
