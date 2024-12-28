extends Node

var scale = 1
var main: Node
var view: EditorView
var config: ConfigManager

func init_node(raw):
    return UI.init_node_hidden_from_raw(raw, {parent=main.canvas})
