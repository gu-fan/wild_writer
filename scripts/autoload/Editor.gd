extends Node

var scale = 1
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

