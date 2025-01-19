extends Node

var scale = 1
var root
var main: Node
var mask: ColorRect
var view: EditorView
var config: ConfigManager
var creative_mode

var is_macos = false
var is_linux = false
var is_windows = false
var is_web = false
var is_android = false
var is_ios = false
var PLATFORM = ''
var HOME_DIR = ''

var is_debug = false

func init_node(raw):
    return UI.init_node_hidden_from_raw(raw, {parent=main.canvas})

# *$HOME-windows*
# On MS-Windows, if $HOME is not defined as an environment variable, then
# at runtime Vim will set it to the expansion of $HOMEDRIVE$HOMEPATH.
# If $HOMEDRIVE is not set then $USERPROFILE is used.
func _init():
    match OS.get_name():
        "Windows":
            is_windows = true
            if OS.get_environment('HOME'):
                HOME_DIR = OS.get_environment("HOME")
            elif OS.has_environment('HOMEDRIVE'):
                HOME_DIR = OS.get_environment("HOMEDRIVE") + OS.get_environment('HOMEPATH')
            else:
                HOME_DIR = OS.get_environment("USERPROFILE")
            PLATFORM = 'windows'
        "macOS":
            is_macos = true
            HOME_DIR = OS.get_environment("HOME")
            PLATFORM = 'macos'
        "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
            is_linux = true
            HOME_DIR = OS.get_environment("HOME")
            PLATFORM = 'linux'
        "Android":
            is_android = true
            HOME_DIR = OS.get_environment("HOME")
            PLATFORM = 'android'
        "iOS":
            is_ios = true
            HOME_DIR = OS.get_environment("HOME")
            PLATFORM = 'ios'
        "Web":
            is_web = true
            HOME_DIR = '/home/web_user'
            PLATFORM = 'web'
    print('%s OS:%s HOME:%s' % [Util.f_msec(), PLATFORM, HOME_DIR])
func _ready():
    root = get_tree().root
    # await get_tree().process_frame
    # Editor.goto('test_style')

func toast(txt):
    view.toast(txt)
# ----------------------------------------
func _get_scn_path(scn):
    # return 'res://test/' + scn + '.gd'
    return scn


func goto(scn, with_loading=false):
    var s = get_tree().current_scene
    var scp = _get_scn_path(scn)
    if !s.has_meta('script') or s.get_meta('script') != scp:
        trans_scene.call_deferred(scn, with_loading)

var _is_transition_scene = false
func trans_scene(scn, with_loading=false):
    if _is_transition_scene: return
    _is_transition_scene = true
    var scn_n = PackedScene.new()
    var node = Node2D.new()
    node.name = 'Scene'
    scn_n.pack(node)
    var scp = _get_scn_path(scn)
    load_scene(scn_n, scp)

func load_scene(_scn, _scrpt):
    root.child_entered_tree.connect(func(_nd): 
        _nd.script = load(_scrpt)
        _nd.set_meta('script', _scrpt)
        await get_tree().create_timer(0.5).timeout
        _is_transition_scene = false
    , CONNECT_ONE_SHOT)
    get_tree().change_scene_to_packed(_scn)

func toggle_ime():
    TinyIME.toggle()
func toggle_setting():
    view.toggle_setting()
func toggle_debug():
    is_debug = !is_debug
    view.set_debug(is_debug)
func log(txt):
    view.log(txt)

func redraw():
    view.redraw()


func toggle_fullscreen():
    var mode = DisplayServer.window_get_mode()
    self.log('got mode %s : %s' % [mode, mode == DisplayServer.WINDOW_MODE_FULLSCREEN])
    if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
