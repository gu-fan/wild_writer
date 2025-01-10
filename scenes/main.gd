extends Node

var editor_view: EditorView
var canvas:CanvasLayer
var firework
var creative_mode_view
var creative_mode
var mask

func _ready():
    canvas = $CanvasLayer
    mask = $CanvasLayer/Mask
    editor_view = $CanvasLayer/EditorView
    firework = $CanvasLayer/Firework
    editor_view.firework = firework

    Editor.main = self
    Editor.view = editor_view
    Editor.view.main = self

    creative_mode_view = $CanvasLayer/CreativeMode
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
        # editor_view.core.command_manager.execute_command(
        #     "open", 
        #     [args[0]]
        # )
        if args[0].get_extension() == 'gd':
            print('got args gd', args)
            Editor.goto(args[0])
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
