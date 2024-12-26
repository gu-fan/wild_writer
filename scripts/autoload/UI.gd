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
        # 检查节点是否正在过渡动画中
        if is_in_transition(nd):
            return
            
        # 使用状态字典来判断当前状态，而不是visible属性
        var is_shown = _node_states.get(nd, nd.visible)
        if is_shown:
            _node_states[nd] = false
            transition_out(nd)
        else:
            _node_states[nd] = true
            transition_in(nd)
    else:
        # 创建节点时，先隐藏它
        nd = create_node_from_raw(raw, params, _internal_mode)
        if nd:
            _node_states[nd] = true
            # 设置初始状态
            _set_initial_state(nd)
            # 执行入场动画
            transition_in(nd)

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
func transition_in(nd: Node) -> void:
    print('trans_in', nd, nd.name)
    # 构建入场过渡动画树
    var trans_tree = _construct_trans_in_tree(nd)
    print('in', trans_tree)
    
    # 如果节点没有过渡配置，直接显示并递归处理子节点
    if trans_tree.is_empty():
        nd.show()
        # 递归处理子节点
        for child in nd.get_children():
            transition_in(child)
        return
    
    # 确保节点可见
    nd.show()
    
    # 执行过渡动画树
    _execute_trans_tree(trans_tree)

func transition_out(nd: Node) -> void:
    # 构建出场过渡动画树
    var trans_tree = _construct_trans_out_tree(nd)
    print('out', trans_tree)
    
    # 如果节点没有过渡配置，直接隐藏
    if trans_tree.is_empty():
        nd.hide()
        return
        
    # 执行过渡动画树
    _execute_trans_tree(trans_tree)

func is_in_transition(nd):
    # 递归检查节点及其子节点是否有正在进行的过渡动画
    if _active_tweens.has(nd):
        return true
        
    for child in nd.get_children():
        if is_in_transition(child):
            return true
            
    return false

# 构建过渡动画树
# 返回格式:
# {
#     type = 'hide' | 'show',
#     delay = 0.0,
#     duration = 0.3,
#     children = [
#         {
#             type = 'fade_in',
#             delay = 0.1,
#             duration = 0.2,
#             children = []
#         }
#     ]
# }
func _construct_trans_in_tree(nd: Node) -> Dictionary:
    var ret = {}
    
    # 获取节点的入场过渡配置
    var trans_in = nd.get_meta("transition_in", {})
    
    # 处理子节点
    var children = []
    var max_child_duration = 0.0
    var max_child_delay = 0.0
    prints('trans_in_tree', nd, nd.visible)
    
    for child in nd.get_children():
        var child_tree = _construct_trans_in_tree(child)
        if not child_tree.is_empty():
            children.append(child_tree)
            # 计算最大持续时间和延迟
            if child_tree.has("duration"):
                max_child_duration = max(max_child_duration, child_tree.duration)
            if child_tree.has("delay"):
                max_child_delay = max(max_child_delay, child_tree.delay)
    
    # 构建当前节点的入场过渡配置
    if trans_in.size() > 0:
        ret = {
            "type": "show",
            "node": nd,
            "prop": trans_in.get("prop", "modulate:a"),
            "from": trans_in.get("from", 0.0),
            "to": trans_in.get("to", 1.0),
            "duration": trans_in.get("dur", 0.3),
            "delay": trans_in.get("delay", 0.0),
            "ease": trans_in.get("ease", Tween.EASE_OUT),
            "trans": trans_in.get("trans", Tween.TRANS_CUBIC),
            "children": children
        }
    elif children.size() > 0:
        # 如果没有过渡配置但有子节点，创建一个容器节点
        ret = {
            "type": "container",
            "node": nd,
            "children": children,
            "duration": max_child_duration,
            "delay": max_child_delay
        }
    
    return ret

func _construct_trans_out_tree(nd: Node) -> Dictionary:
    var ret = {}
    
    # 获取节点的出场过渡配置
    var trans_out = nd.get_meta("transition_out", {})
    
    # 处理子节点
    var children = []
    var max_child_duration = 0.0
    var max_child_delay = 0.0

    prints('trans_out_tree', nd, nd.visible)
    
    for child in nd.get_children():
        var child_tree = _construct_trans_out_tree(child)
        if not child_tree.is_empty():
            children.append(child_tree)
            # 计算最大持续时间和延迟
            if child_tree.has("duration"):
                max_child_duration = max(max_child_duration, child_tree.duration)
            if child_tree.has("delay"):
                max_child_delay = max(max_child_delay, child_tree.delay)
    
    # 构建当前节点的出场过渡配置
    if trans_out.size() > 0:
        ret = {
            "type": "hide",
            "node": nd,
            "prop": trans_out.get("prop", "modulate:a"),
            "from": trans_out.get("from", 1.0),
            "to": trans_out.get("to", 0.0),
            "duration": trans_out.get("dur", 0.3),
            "delay": trans_out.get("delay", 0.0),
            "ease": trans_out.get("ease", Tween.EASE_IN),
            "trans": trans_out.get("trans", Tween.TRANS_CUBIC),
            "children": children
        }
    elif children.size() > 0:
        # 如果没有过渡配置但有子节点，创建一个容器节点
        ret = {
            "type": "container",
            "node": nd,
            "children": children,
            "duration": max_child_duration,
            "delay": max_child_delay
        }
    
    return ret

# 跟踪节点的当前tween
var _active_tweens: Dictionary = {}

# 跟踪节点的显示状态
var _node_states: Dictionary = {}

func _execute_trans_tree(tree: Dictionary) -> void:
    if tree.is_empty():
        return
        
    print('execute', tree.node, tree.node.visible, tree)
    
    # 处理当前节点的过渡
    if tree.type == "show" or tree.type == "hide":
        var node = tree.node
        
        # 如果节点有正在进行的tween，先停止它
        if _active_tweens.has(node):
            if is_instance_valid(_active_tweens[node]):
                _active_tweens[node].kill()
            _active_tweens.erase(node)
        
        var tween = create_tween()
        tween.set_parallel(true)
        _active_tweens[node] = tween
        
        var prop = tree.prop
        var from = tree.from
        var to = tree.to
        var duration = tree.duration
        var delay = tree.delay
        
        # 如果是显示动画，确保节点和所有父节点都可见
        if tree.type == "show":
            var parent = node
            while parent:
                parent.show()
                parent = parent.get_parent()
        
        # 设置初始值
        _set_property(node, prop, from)
        
        # 创建补间动画
        tween.tween_property(
            node, 
            prop,
            to,
            duration
        ).set_trans(tree.trans)\
         .set_ease(tree.ease)\
         .set_delay(delay)
        
        # 如果是隐藏过渡，在动画结束时隐藏节点
        if tree.type == "hide":
            tween.chain().tween_callback(func():
                node.hide()
                _active_tweens.erase(node)
                _node_states[node] = false
            )
        else:
            # 动画结束时清理tween引用
            tween.chain().tween_callback(func():
                _active_tweens.erase(node)
                _node_states[node] = true
            )
    
    # 处理子节点
    if tree.has("children"):
        for child in tree.children:
            _execute_trans_tree(child)

# 辅助函数：设置属性值
func _set_property(node: Node, prop: String, value) -> void:
    #if ":" in prop:
        #var parts = prop.split(":")
        #var obj = node
        #for i in range(parts.size() - 1):
            #obj = obj.get(parts[i])
        #obj.set(parts[-1], value)
    #else:
        #node.set(prop, value)
    node.set_indexed(prop, value)
# 使用示例：
# 在节点上设置过渡配置
"""
var panel = Panel.new()
panel.set_meta("transition_in", {
    "prop": "modulate:a",
    "from": 0.0,
    "to": 1.0,
    "dur": 0.3,
    "delay": 0.0,
    "ease": Tween.EASE_OUT,
    "trans": Tween.TRANS_CUBIC
})

# 执行过渡
var trans_tree = _construct_trans_tree(panel)
_execute_trans_tree(trans_tree)
"""

func _set_initial_state(node: Node) -> void:
    # 递归设置所有节点的初始状态
    for child in node.get_children():
        _set_initial_state(child)
        
    # 如果节点有入场动画配置，设置其初始状态
    var trans_in = node.get_meta("transition_in", {})
    if trans_in.size() > 0:
        var prop = trans_in.get("prop", "modulate:a")
        var from = trans_in.get("from", 0.0)
        _set_property(node, prop, from)
        prints('set_initial_state', node, prop, from)
