extends Node

var editor_view: EditorView
var canvas:CanvasLayer
var firework
var creative_mode_view
var creative_mode

func _ready():
    canvas = $CanvasLayer
    editor_view = $CanvasLayer/EditorView
    firework = $CanvasLayer/Firework
    editor_view.firework = firework

    Editor.main = self
    Editor.view = editor_view



    creative_mode_view = $CanvasLayer/CreativeMode
    creative_mode_view.set_goal(1000)
    creative_mode = creative_mode_view.creative_mode
    Editor.creative_mode = creative_mode

    
    # 设置初始状态

    editor_view.init()

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

# ---------------------------
# func _test():
#     $CanvasLayer/Box/Toggle.pressed.connect(_toggle_locale)
#     $CanvasLayer/Box/Setting.pressed.connect(_show_ui)
#     $CanvasLayer/Box/Old.pressed.connect(_show_old_ui)

# func _show_ui():
#     UI.toggle_node_from_raw('ui/settings:Settings', {parent=$CanvasLayer})
# func _show_old_ui():
#     UI.toggle_node_from_raw('ui/settings:OldSettings', {parent=$CanvasLayer})
    # transition _ in / out
    # use meta to store and trans all child
# ---------------------------
