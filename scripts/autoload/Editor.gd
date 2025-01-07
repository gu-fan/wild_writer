extends Node

var scale = 1
var root
var main: Node
var view: EditorView
var config: ConfigManager
var creative_mode

var is_macos = false
var is_linux = false
var is_windows = false
var is_web = false
var is_android = false
var is_ios = false

func init_node(raw):
	return UI.init_node_hidden_from_raw(raw, {parent=main.canvas})

func _init():
	match OS.get_name():
		"Windows":
			is_windows = true
		"macOS":
			is_macos = true
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			is_linux = true
		"Android":
			is_android = true
		"iOS":
			is_ios = true
		"Web":
			is_web = true
func _ready():
	root = get_tree().root
	# await get_tree().process_frame
	# Editor.goto('test_style')

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
