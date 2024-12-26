extends Node

enum {
    PRESET_TOP_LEFT = 0,
    PRESET_TOP_RIGHT = 1,
    PRESET_BOTTOM_LEFT = 2,
    PRESET_BOTTOM_RIGHT = 3,
    PRESET_CENTER_LEFT = 4,
    PRESET_CENTER_TOP = 5,
    PRESET_CENTER_RIGHT = 6,
    PRESET_CENTER_BOTTOM = 7,
    PRESET_CENTER = 8,
    PRESET_LEFT_WIDE = 9,
    PRESET_TOP_WIDE = 10,
    PRESET_RIGHT_WIDE = 11,
    PRESET_BOTTOM_WIDE = 12,
    PRESET_VCENTER_WIDE = 13,
    PRESET_HCENTER_WIDE = 14,
    PRESET_FULL_RECT = 15,
    PRESET_LEFT_CENTER = 4,
    PRESET_TOP_CENTER = 5,
    PRESET_RIGHT_CENTER = 6,
    PRESET_BOTTOM_CENTER = 7,
}
enum {
    GROW_DIRECTION_BEGIN,
    GROW_DIRECTION_END,
    GROW_DIRECTION_BOTH,
}
enum {
    MOUSE_FILTER_STOP,
    MOUSE_FILTER_PASS,
    MOUSE_FILTER_IGNORE,
}
enum {
    TEXTURE_FILTER_PARENT_NODE,
    TEXTURE_FILTER_NEAREST,
    TEXTURE_FILTER_LINEAR,
    TEXTURE_FILTER_NEAREST_WITH_MIPMAPS,
    TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,
    TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC,
    TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC,
    TEXTURE_FILTER_MAX,
}

# ------------------------------------
# BASICS
# ------------------------------------
func set_layout(node, preset, offset=Vector2.ZERO):
    UILayout.set_layout(node, preset, offset)
# ------------------------------------
# Create Node in UICreateNode
func toggle_node_from_raw(raw, params={}, _internal_mode=0) -> void:
    var nd = get_node_or_null_from_raw(raw, params, _internal_mode)
    if nd:
        if nd.visible:
            if nd.has_method('trans_out'):
                # UITrans.out(nd)
                nd.trans_out()
            else:
                nd.hide()
        else:
            if nd.has_method('trans_in'):
                nd.trans_in()
            else:
                nd.show()
    else:
        create_node_from_raw(raw, params, _internal_mode)

func get_or_create_node_from_raw(raw, params={}, _internal_mode=0):
    return UICreateNode.get_or_create_node_from_raw(raw, params, _internal_mode)

func get_node_or_null_from_raw(raw, params={}, _internal_mode=0):
    return UICreateNode.get_node_or_null_from_raw(raw, params, _internal_mode)

func create_node_from_raw(raw, params={}, _internal_mode=0):
    return UICreateNode.create_node_from_raw(raw, params, _internal_mode)

func get_node_or_null_from_dic(params:Dictionary={}, _internal_mode=0)->Node:
    return UICreateNode.get_node_or_null_from_dic(params, _internal_mode)

func get_or_create_node(params:Dictionary={}, _internal_mode=0)->Node:
    return UICreateNode.get_or_create_node(params, _internal_mode)

func create_node(params:Dictionary={}, _internal_mode=0)->Node:
    return UICreateNode.create_node(params, _internal_mode)
# ------------------------------------
# Setup Node in UISetNode
func set_font(_nd:Node, font_path):
    UISetNode.set_font(_nd, font_path)

func set_font_size(_nd:Node, font_size:float):
    UISetNode.set_font_size(_nd, font_size)

func set_font_color(_nd:Node, color):
    UISetNode.set_font_color(_nd, color)

func set_separation(_nd, val):
    UISetNode.set_separation(_nd, val)

func set_flat_style(_nd, params={}):
    UISetNode.set_flat_style(_nd, params)

func get_flat_style(params={}):
    return UISetNode.get_flat_style(params)

func get_font_color(_nd:Node):
    return UISetNode.get_font_color(_nd)

func set_image(_nd:Node, img_data):
    UISetNode.set_image(_nd, img_data)
# ------------------------------------
