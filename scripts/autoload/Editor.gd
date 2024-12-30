extends Node

var scale = 1
var main: Node
var view: EditorView
var config: ConfigManager

var is_macos = false
var is_linux = false
var is_windows = false
var is_web = false

func init_node(raw):
    return UI.init_node_hidden_from_raw(raw, {parent=main.canvas})
