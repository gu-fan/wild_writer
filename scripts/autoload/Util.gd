extends Node
# v 1.0.2
# writer version
## A brief description of the class's role and functionality.
##
## The description of the script, what it can do,
## and any further detail.
##

# ------------------------------
func _process(delta):
    _run_ttl_process(delta)
# ------------------------------
func generate_random_id(parts: int, lengths: Array, n: int = 0) -> String:
    var id_parts = []
    for i in range(parts):
        var part = int(randf_range(0, 1) * 65536) & 0xFFFF
        id_parts.append(("%0" + str(lengths[i]) + "x") % part)
    
    var id_str = "".join(id_parts)
    if n:
        return ("%0" + str(lengths[0] - 1) + "x" % n).substr(0, lengths[0] - 1) + id_str
    return id_str

# 5位随机ID
func mini_id(n: int = 0) -> String:
    return generate_random_id(2, [2, 3], n)

# 8位随机ID
func id(n: int = 0) -> String:
    return generate_random_id(2, [4, 4], n)

# 11位随机ID
func long_id(n: int = 0) -> String:
    return generate_random_id(3, [4, 4, 3], n)
#--------------------------
## fast and simple id generator
func sid(k=null):
    if k: return mini_id(hash(k))
    return mini_id()
func mid(k=null):
    if k: return id(hash(k))
    return id()
func lid(k=null):
    if k: return long_id(hash(k))
    return long_id()
# --------------------------------------------
func is_valid(nd):
    return nd and is_instance_valid(nd)
func is_in_tree(nd):
    return nd and is_instance_valid(nd) and nd.is_inside_tree()
func is_null(nd):
    return is_same(nd, null)
# --------------------------------------------

func sec():
    return int(Time.get_ticks_msec() / 100) / 10.0 # 3.3 sec
func msec():
    return Time.get_ticks_msec()
func usec():
    return Time.get_ticks_usec()
func keycode_to_string(k):
    return OS.get_keycode_string(k)
func string_to_keycode(s):
    return OS.find_keycode_from_string(str(s))
func clone(nd):
    return nd.duplicate(DUPLICATE_USE_INSTANTIATION)
func erase_keys(a={}, ks=[]):
    for k in ks: a.erase(k)
func set_parent(child, newp, _internal_mode=0):
    # can set invernal besides 'child.reparent(newp)'
    if child.get_parent() == newp:
        return
    var oldp = child.get_parent()
    if oldp:
        oldp.remove_child(child)
    if _internal_mode:
        newp.add_child(child, false, _internal_mode)
    else:
        newp.add_child(child)
    child.set_owner(newp.get_owner())
func clear_child(node): # XXX: not cleaned?
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()
# color_rot('FF33FF', 0.1, 0.1)
# color_rot('FF33FF', {'H':0.1})
func color_roll(clr, h=0, s=0, v=0):
    var c = Color(clr)
    if h is Dictionary:
        var dic = h
        h = dic.get('H', 0)
        s = dic.get('S', 0)
        v = dic.get('V', 0)
    if h: c.h = wrapf(c.h + h, 0, 1)
    if s: c.s = c.s + s
    if v: c.v = c.v + v
    return c
# if is_class_name(n, 'Node25D'): xxxx
func get_class_name(nd):
    var cn = ''
    var sc = nd.get_script()
    if sc: cn = sc.get_global_name()
    return cn
func is_class_name(nd, _n):
    return get_class_name(nd) == _n
# ------------------------------
func freeze(node):
    node.set_process(false)
    node.set_physics_process(false)
    node.set_process_input(false)
    node.set_process_internal(false)
    node.set_process_unhandled_input(false)
    node.set_process_unhandled_key_input(false)
func unfreeze(node):
    node.set_process(true)
    node.set_physics_process(true)
    node.set_process_input(true)
    node.set_process_internal(true)
    node.set_process_unhandled_input(true)
    node.set_process_unhandled_key_input(true)

var _is_freezing = false
var _is_unfreezing = false
func freeze_engine(delay, scale=0.15):
    if _is_freezing: return
    _is_freezing = true
    wait(delay, func():
        Engine.set('time_scale', scale)
        _is_freezing = false
    )
func unfreeze_engine(delay):
    if _is_unfreezing: return
    _is_unfreezing = true
    wait(delay, func(): 
        Engine.set('time_scale', 1.0)
        _is_unfreezing = false
    )
func set_global_speed_scale(v):
    Engine.time_scale = v
func get_global_speed_scale(v):
    return Engine.time_scale
# ------------------------------
# WAIT FUNCTIONS

## 等待时间常量
const MIN_WAIT_TIME := 0.01
const DEFAULT_WAIT_TIME := 0.02

## 等待指定时间
## [br]用法示例:[br]
## [codeblock]
## await Util.wait(0.5)  # 等待0.5秒
## Util.wait(0.5, func(): print("Done"))  # 0.5秒后打印Done
## [/codeblock]
## [param time] 等待时间(秒)，最小值为0.01
## [param callback] 可选的回调函数
## [return] 计时器的timeout信号
func wait(time: float = DEFAULT_WAIT_TIME, callback: Callable = Callable()) -> Signal:
    # 确保时间不小于最小值
    var actual_time := maxf(time, MIN_WAIT_TIME)
    
    # 创建并配置计时器
    var timer := get_tree().create_timer(actual_time)
    
    if callback and callback.is_valid():
        timer.timeout.connect(callback, CONNECT_ONE_SHOT)
    
    return timer.timeout

## 等待到下一帧
## [br]用法示例:[br]
## [codeblock]
## await Util.next_frame()  # 等待到下一帧
## Util.next_frame(func(): print("Next frame"))  # 下一帧时打印
## [/codeblock]
## [param callback] 可选的回调函数
## [return] process_frame信号
func next_frame(callback: Callable = Callable()) -> Signal:
    if callback and callback.is_valid():
        get_tree().process_frame.connect(callback, CONNECT_ONE_SHOT)
    return get_tree().process_frame

## 等待指定时间后调用函数
## [br]与wait不同，这个函数不返回信号，只执行回调
## [param time] 等待时间(秒)
## [param callback] 必需的回调函数
func wait_call(time: float, callback: Callable) -> void:
    if not callback or not callback.is_valid():
        push_warning("wait_call: Invalid callback provided")
        return
        
    var actual_time := maxf(time, MIN_WAIT_TIME)
    var timer := get_tree().create_timer(actual_time)
    timer.timeout.connect(callback, CONNECT_ONE_SHOT)

## 等待指定时间后设置节点属性
## [param time] 等待时间(秒)
## [param node] 目标节点
## [param prop] 属性名
## [param value] 要设置的值
func wait_set(time: float, node: Node, prop: String, value: Variant) -> void:
    wait_call(time, func():
        if not is_valid(node): 
            push_warning("wait_set: Node became invalid")
            return
        node.set(prop, value)
    )

## 等待指定时间后释放节点
## [param node] 要释放的节点
## [param time] 等待时间(秒)
func wait_free(node: Node, time: float = 0.0) -> void:
    if not is_valid(node):
        push_warning("wait_free: Invalid node provided")
        return
        
    wait_call(time, func():
        if not is_valid(node): return
        var parent := node.get_parent()
        if parent: parent.remove_child(node)
        node.queue_free()
    )

## 等待指定时间后显示节点
## [param node] 目标节点
## [param time] 等待时间(秒)
func wait_show(node: Node, time: float = 0.0) -> void:
    if not is_valid(node):
        push_warning("wait_show: Invalid node provided")
        return
        
    wait_call(time, func():
        if not is_valid(node): return
        node.show()
    )

## 等待指定时间后隐藏节点
## [param node] 目标节点
## [param time] 等待时间(秒)
func wait_hide(node: Node, time: float = 0.0) -> void:
    if not is_valid(node):
        push_warning("wait_hide: Invalid node provided")
        return
        
    wait_call(time, func():
        if not is_valid(node): return
        node.hide()
    )

func wait_freeze(node:Node, time:float=0.0):
    wait_call(time, func():
        if !is_valid(node): return
        freeze(node)
    )
func wait_unfreeze(node:Node, time:float=0.0):
    wait_call(time, func():
        if !is_valid(node): return
        unfreeze(node)
    )
#------------------------------------
func wait_incr(time:float, node:Node, prop:String, count:float):
    wait_call(time, incr.bind(node, prop, count))
func wait_decr(time:float, node:Node, prop:String, count:float):
    wait_call(time, decr.bind(node, prop, count))
func wait_toggle(time:float, node:Node, prop:String):
    wait_call(time, toggle.bind(node, prop))

func toggle(node, prop:String):
    if !is_valid(node): return
    var cur = node.get(prop)
    if cur == null: cur = false
    node.set(prop, !cur)

func incr(node, prop:String, count):
    if !is_valid(node): return
    var cur = node.get(prop)
    if cur == null: cur = 0
    node.set(prop, cur + count)
func decr(node, prop:String, count):
    incr(node, prop, -count)
# ------------------------------
# ttl cache in 3 min
const TTL_CHECK_TIME = 120 # 2 min
const MAX_TTL = 240 # 4 min
var _ttl = {}
var _ttl_cache = {}
var _last_ttl_tick = 0
func _run_ttl_process(_delta):
    if _ttl.is_empty(): return
    if _last_ttl_tick < TTL_CHECK_TIME:
        _last_ttl_tick += _delta
    else:
        clear_ttl()
        _last_ttl_tick = 0

func _get_ttl(id):
    if not _ttl_cache.has(id): 
        _ttl_cache[id] = {}
        _ttl[id] = Time.get_ticks_msec()
    return _ttl_cache[id]

func get_ttl(id, key=null, default=null):
    var _c = _get_ttl(id)
    if key != null:
        return _c.get(key, default)
    else:
        return _c

func set_ttl(id, key, value):
    var _c = _get_ttl(id)
    _c[key] = value

func erase_ttl(id):	
    _ttl.erase(id)
    _ttl_cache.erase(id)

func clear_ttl():
    var time = Time.get_ticks_msec()
    var count = 0
    for k in _ttl:
        if time - _ttl[k] > MAX_TTL:
            _ttl.erase(k)
            _ttl_cache.erase(k)
            count += 1
# -------------------------------
var _cache = {}
func _get_cache(id):
    if not _cache.has(id): 
        _cache[id] = {}
    return _cache[id]
func get_cache(id, key=null, default=null):
    var _c = _get_cache(id)
    if key != null:
        return _c.get(key, default)
    else:
        return _c

func set_cache(id, key, value):
    var _c = _get_cache(id)
    _c[key] = value
func erase_cache(id):	_cache.erase(id)
func clear_cache():	_cache.clear()
# ------------------------------
## call instant, if multi called in n sec, skip
#   for i in 5:
#       await Util.wait(0.2)
#       Util.throttle('pp', 0.5, p)
#   this will execute 2 times at 0s, 0.6s
#  |x x|x x|x x| 
#  |o  |o  |o  | 
func throttle(id:String, time:float, callback:Callable):
    var ticks = Time.get_ticks_msec()
    var _th_cache = get_ttl('_th_' + id)
    if not _th_cache.has('interval'):
        _th_cache['interval'] = time * 1000
        _th_cache['last'] = ticks
        _th_cache['count'] = 1
        callback.call()
        return 1
    if ticks - _th_cache['last'] > _th_cache['interval']:
        _th_cache['last'] = ticks
        _th_cache['count'] += 1
        callback.call()
        return _th_cache['count']
    else:
        return false
# -----------------------------
## delay call in n sec, if multi call, keep delay. aka. debounce
#   for i in 5:
#       await Util.wait(0.2)
#       Util.delay('pp', 1.0, p)
#   only call once after last time 1.0s
#  |x x|x x|   | 
#  |   |   |  o| 
# 
func delay(id:String, time:float, callback=null):
    var _de_cache = get_ttl('_de_' + id)
    if _de_cache.has('timer') and !is_instance_valid(_de_cache['timer']):
        _de_cache.erase('timer')

    if not _de_cache.has('timer'):
        var timer = Timer.new()
        timer.wait_time = time
        timer.one_shot = true
        timer.timeout.connect(self._on_delay_end.bind(id))
        _de_cache['timer'] = timer
        _de_cache['callback'] = callback
        add_child(timer)
        timer.start()
        return timer.timeout
    else:
        var timer = _de_cache['timer']
        timer.start(time)
        _de_cache['callback'] = callback # may update callback
        return timer.timeout
func _on_delay_end(id):
    var _de_cache = get_ttl('_de_' + id)
    if _de_cache.has('callback'):
        _de_cache['timer'].queue_free()
        var cb = _de_cache['callback']
        if cb and cb.is_valid():
            cb.call()
        erase_ttl('_de_' + id)
func stop_delay(id):
    var _de_cache = get_ttl('_de_' + id)
    if _de_cache.has('timer'):
        _de_cache['timer'].stop()
        _de_cache['timer'].queue_free()
        erase_ttl('_de_' + id)
# -----------------------------
## repeat call n times with m interval
#  Util.repeat('pp', 5, 0.5, p)
#  will run 5 times with 0.5s interval
#  x|  o|  o|  o| 
func repeat(id:String, count:int=10, interval:float=1.0, callback=null, params={}):
    var _re_cache = get_cache('_re_' + id)
    if _re_cache.has('timer') and !is_instance_valid(_re_cache['timer']):
        _re_cache.erase('timer')
    if not _re_cache.has('timer'):
        var timer = Timer.new()
        timer.wait_time = interval
        timer.one_shot = false
        timer.timeout.connect(self._on_repeat.bind(id))
        _re_cache['timer'] = timer
        _re_cache['callback'] = callback
        _re_cache['count'] = count
        _re_cache['total_time'] = 0
        if params.has('end_call'): _re_cache['end_call'] = params.end_call
        # if params.has('intv_func'): _re_cache['intv_func'] = params.intv_func
        add_child(timer)
        timer.start()
        return timer
    else:
        _re_cache['timer'].start(interval)
        _re_cache['count'] = count
        return _re_cache['timer']
func _on_repeat(id):
    var _re_cache = get_cache('_re_' + id)
    if _re_cache.has('callback'):
        _re_cache['count'] -= 1
        var wt = _re_cache.timer.wait_time
        _re_cache.total_time += wt
        # ?
        # if _re_cache.has('intv_func') and _re_cache.intv_func.is_valid():
        #     _re_cache.timer.wait_time = _re_cache.intv_func.call(wt, _re_cache.total_time, _re_cache.count)

        if _re_cache['count'] < 0:
            if _re_cache.has('end_call') and _re_cache.end_call.is_valid():
                _re_cache.end_call.call()
            _re_cache['timer'].queue_free()
            erase_cache('_re_' + id)
        else:
            var cb = _re_cache['callback']
            if cb and cb.is_valid():
                cb.call()
func stop_repeat(id):
    var _re_cache = get_cache('_re_' + id)
    if _re_cache.has('end_call') and _re_cache.end_call.is_valid():
        _re_cache.end_call.call()
    if _re_cache.has('timer'):
        _re_cache['timer'].queue_free()
        erase_cache('_re_' + id)
# --------------------------------------------------------
# --------------------------------------------------------
func __join_log_txt(t0, t1='', t2='', t3='', t4='', t5='', t6=''):
    var _s = ''
    for v in [t0, t1, t2, t3, t4, t5, t6]:
        if v is String and v == '': continue
        _s += str(v) + ' '
    return _s
func log(t0, t1='', t2='', t3='', t4='', t5='', t6=''):
    var _s = __join_log_txt(t0, t1, t2, t3, t4, t5, t6)
    print_rich('[color=green]'+_s+'[/color]')
func warn(t0, t1='', t2='', t3='', t4='', t5='', t6=''):
    var _s = __join_log_txt(t0, t1, t2, t3, t4, t5, t6)
    print_rich('[color=orange]'+_s+'[/color]')
func err(t0, t1='', t2='', t3='', t4='', t5='', t6=''):
    var _s = __join_log_txt(t0, t1, t2, t3, t4, t5, t6)
    print_rich('[color=red]'+_s+'[/color]')
func log_time(t0, t1='', t2='', t3='', t4='', t5='', t6=''):
    var _s = '[color=blue]ms:%07d[/color] ' % Util.msec() + __join_log_txt(t0, t1, t2, t3, t4, t5, t6)
    print_rich(_s)
func log_rich(t0, t1='', t2='', t3='', t4='', t5='', t6=''):
    var _s = __join_log_txt(t0, t1, t2, t3, t4, t5, t6)
    print_rich(_s)
# --------------------------------------------
func curve(values, linear=false):
    var ret = Curve.new()
    var step = 1.0 / (values.size()  - 1)
    if linear:
        for i in values.size():
            ret.add_point(Vector2(i*step, values[i]), 0, 0, 1, 1)
    else:
        for i in values.size():
            ret.add_point(Vector2(i*step, values[i]))
    return ret

var _curves_cache = {}
func curve_texture(values, linear=false):
    var id = hash(values)
    if not _curves_cache.has(id):
        _curves_cache[id] = CurveTexture.new()
        _curves_cache[id].curve = curve(values, linear)
    return _curves_cache[id]

func noise_texture(params={}):
    var texture = NoiseTexture2D.new()

    var noise = FastNoiseLite.new()
    if params.has('fractal'):
        noise.fractal_type = params.fractal
    if params.has('frequency'):
        noise.frequency = params.frequency
    if params.has('octaves'):
        noise.fractal_octaves = params.octaves
    if params.has('gain'):
        noise.fractal_gain = params.gain
    noise.noise_type = params.get('type', 0)
    texture.noise = noise
    if params.has('seamless'):
        texture.seamless = params.seamless
    texture.generate_mipmaps = false
    noise.seed = randi_range(0, 100000)

    return texture

var _noise = {}
func get_noise(id, params={}):
    if not _noise.has(id):
        _noise[id] = noise_texture(params)
    return _noise[id]

var _gradient1d_cache = {}
func gradient1D(colors):
    if _gradient1d_cache.has(colors):
        return _gradient1d_cache[colors]

    var tex = GradientTexture1D.new()
    tex.gradient = gradient(colors)

    _gradient1d_cache[colors] = tex

    return tex

var _gradient_cache = {}
func gradient(colors):
    var step = 1.0 / (colors.size()  - 1)
    var _gr = Gradient.new()

    for i in colors.size():
        _gr.add_point(i*step, Color(colors[i]))
    # NOTE: _gr have two initial value
    _gr.remove_point(0)
    _gr.remove_point(0)
    return _gr

func get_color_from_gradient(val, val_range, gradient):
    var off = inverse_lerp(val_range[0], val_range[1], val)
    off = clamp(off, 0.0, 1.0)
    return gradient.sample(off)

func gradient2D(colors, params={}):

    var tex = GradientTexture2D.new()
    tex.gradient = gradient(colors)

    tex.width = params.get('width', 64)
    tex.height = params.get('height', 64)
    tex.fill = params.get('fill', 0) # FILL_LINEAR, FILL_RADIAL, FILL_SQUARE
    tex.fill_from = params.get('from', Vector2(0, 0))
    tex.fill_to = params.get('to', Vector2(1, 0))

    return tex

# ------------------------------------


# ------------------------------------
func blend(node:Node, mode:int, light_mode:int=0):
    if mode == -1:
        node.material = null
        if light_mode == 0:
            return
    if not (node.material and node.material.has_meta('blend') and node.material.get_meta('blend') == mode) or light_mode:
        var mat = CanvasItemMaterial.new()
        if mode and mode != -1: 
            mat.blend_mode = mode
            mat.set_meta('blend', mode)
        if light_mode: mat.light_mode = light_mode
        node.material = mat
        # print(node,node.get_parent()._base_params, mode, light_mode)

# _raw : res://xx
# _raw : Fx/shader:xxxxx
# 
func shade(node:Node, _raw:String, params={}):
    var _has_same_shade = false
    if node.material and node.material.has_meta('shader') and node.material.get_meta('shader') == _raw:
        _has_same_shade = true
    if !_has_same_shade: # create _new
        var mat   
        if _raw.match("res://*"): # res://xxxx.gdshader, load that
            mat = ShaderMaterial.new()
            mat.shader = load(_raw)
        else:
            var _config = Raw.load(_raw, true)
            if _config == null: _config = {}
            if _config.has('material'): # load config mat (a mat resource)
                mat = load(_config.material)
            else:
                mat = ShaderMaterial.new()
                if _config.has('shader'):
                    mat.shader = load(_config.shader) # load config shader
                else:
                    var _name = _raw.split(':')[-1] # load shader by name
                    mat.shader = load('res://assets/shaders/%s.gdshader' % _name)

            if _config.has('params'):
                params.merge(_config.params)

        for k in params:
            if k == 'color': 
                mat.set_shader_parameter(k, Color(params[k]))
            else:
                mat.set_shader_parameter(k, params[k])

        mat.set_meta('shader', _raw)
        node.material = mat
    else:

        for k in params:
            if k == 'color': 
                node.material.set_shader_parameter(k, Color(params[k]))
            else:
                node.material.set_shader_parameter(k, params[k])

func remove_material(node:Node):
    if node: node.material = null
func unshade(node:Node):
    if node: node.material = null

# -------------------------------
func get_global_position_over_canvas(canvas_pos):
    # get the global position with given canvas position
    return get_viewport().canvas_transform.affine_inverse() * (canvas_pos)

# https://docs.godotengine.org/en/stable/tutorials/2d/2d_transforms.html#introduction
func get_canvas_position(global_pos):
    return get_viewport().canvas_transform * (get_viewport().global_canvas_transform * global_pos)

func get_node_canvas_position(node):
    return node.get_global_transform_with_canvas() * node.position
# ---------------------------------------------
func get_canvas_pos_over_world(world_pos):
    return get_canvas_position(world_pos)
func get_world_pos_over_canvas(cvs_pos):
    return get_global_position_over_canvas(cvs_pos)

func get_grid_pos_over_canvas(cvs_pos):
    var world_pos = get_global_position_over_canvas(cvs_pos)
    # world_pos = world_pos - Vector2(15, 15)
    # return Pos.world_to_grid(world_pos).snapped(Vector2(2, 2)) / 2
    # world_pos = world_pos - Vector2(5, 5)
    return Pos.world_to_grid(world_pos, Editor.scale)
func get_canvas_pos_over_grid(grid_pos):
    var world_pos = Pos.grid_to_world(grid_pos, Editor.scale)
    return get_canvas_position(world_pos)

func get_canvas_percent_over_grid(grid_pos):
    var world_pos = Pos.grid_to_world(grid_pos, Editor.scale)
    return get_canvas_percent_over_world(world_pos)

func get_canvas_percent_over_world(world_pos):
    var cvs = get_canvas_position(world_pos)
    var size = UI.get_viewport_size()
    return Vector2(cvs.x / size.x , cvs.y / size.y)

# --------------------------
func free_at(node:Node, time:float=0.5):
    wait(time, node.queue_free)

func hide_at(node:Node, time:float=0.5):
    wait(time, node.hide)

func fade_to(node:Node, color, time:float=0.1, _prop='color', _from=''):
    var twn = node.create_tween()
    if _prop == 'color' and not _prop in node:
        _prop = 'modulate'
    twn.tween_interval(time)
    if _from:
        node.set(_prop, Color(_from))
        twn.tween_property(node, _prop, Color(color), 0.3)
    else:
        twn.tween_property(node, _prop, Color(color), 0.3)

func fade_in(node:Node, time:float=0.0, dur:float=0.0):
    if dur == 0.0: dur = 0.3
    node.show()
    var twn = node.create_tween()
    node.modulate.a = 0
    twn.tween_interval(time)
    twn.tween_property(node, 'modulate:a', 1.0, dur)

func fade_out(node:Node, time:float=0.0, dur:float=0.0):
    if dur == 0.0: dur = 0.3
    node.show()
    var twn = node.create_tween()
    twn.tween_interval(time)
    twn.tween_property(node, 'modulate:a', 0, dur)
    twn.tween_callback(node.hide)

func fade_free(node:Node, time:float=0.0, dur:float=0.0):
    if !is_in_tree(node): return
    if dur == 0.0: dur = 0.3
    node.show()
    var twn = node.create_tween()
    twn.tween_interval(time)
    twn.tween_property(node, 'modulate:a', 0, dur)
    twn.tween_callback(node.get_parent().remove_child.bind(node))
    twn.tween_callback(node.queue_free)

# ----------------------------
func _get_orig(nd, k):
    var _k = k.replace(':', '_')
    if nd.has_meta('orig_' + _k):
        return nd.get_meta('orig_' + _k)
    else:
        var v = nd.get_indexed(k)
        nd.set_meta('orig_' + _k, v)
        return v
func _trans_in(node, prop, from, to, dur, delay):
    if dur == 0.0: dur = 0.2
    node.show()
    node.modulate.a = 0.0
    if from != null: node.set_indexed(prop, from)
    var twn = node.create_tween()
    twn.tween_interval(delay)
    twn.tween_property(node, prop, to, dur)
    twn.set_parallel()
    twn.tween_property(node, 'modulate:a', 1.0, dur * 0.3)
func _trans_out(node, prop, from, to, dur, delay):
    if dur == 0.0: dur = 0.2
    node.show()
    node.modulate.a = 1.0
    if from != null: node.set_indexed(prop, from)
    var twn = node.create_tween()
    twn.tween_interval(delay)
    twn.tween_property(node, prop, to, dur)
    twn.set_parallel()
    twn.tween_property(node, 'modulate:a', 0.0, dur * 0.6).set_delay(dur*0.4)
    twn.set_parallel(false)
    twn.tween_callback(node.hide)
func _trans_in_no_fade(node, prop, from, to, dur, delay):
    if dur == 0.0: dur = 0.2
    node.show()
    node.modulate.a = 1.0
    if from != null: node.set_indexed(prop, from)
    var twn = node.create_tween()
    twn.tween_interval(delay)
    twn.tween_property(node, prop, to, dur)
func _trans_out_no_fade(node, prop, from, to, dur, delay):
    if dur == 0.0: dur = 0.2
    node.show()
    node.modulate.a = 1.0
    if from != null: node.set_indexed(prop, from)
    var twn = node.create_tween()
    twn.tween_interval(delay)
    twn.tween_property(node, prop, to, dur)
    twn.tween_callback(node.hide)
# --------------------------
func rotate_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset = node.size / 2
    var orig_scale = _get_orig(node, 'rotation_degrees')
    _trans_in(node, 'rotation_degrees', orig_scale-45*ext, orig_scale, dur, time)
func rotate_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset = node.size / 2
    var orig_scale = _get_orig(node, 'rotation_degrees')
    _trans_out(node, 'rotation_degrees', orig_scale, orig_scale+45*ext, dur, time)
func rotate_inv_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset = node.size / 2
    var orig_scale = _get_orig(node, 'rotation_degrees')
    _trans_in(node, 'rotation_degrees', orig_scale+45*ext, orig_scale, dur, time)
func rotate_inv_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset = node.size / 2
    var orig_scale = _get_orig(node, 'rotation_degrees')
    _trans_out(node, 'rotation_degrees', orig_scale, orig_scale-45*ext, dur, time)

func scale_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var orig_scale = _get_orig(node, 'scale')
    if 'pivot_offset' in node:
        node.pivot_offset = node.size / 2
    _trans_in(node, 'scale', Vector2.ZERO, orig_scale*ext, dur, time)

func scale_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset = node.size / 2
    var orig_scale = _get_orig(node, 'scale')
    _trans_out(node, 'scale', orig_scale*ext, orig_scale*3.0*ext, dur, time)

func scale_inv_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var orig_scale = _get_orig(node, 'scale')
    if 'pivot_offset' in node:
        node.pivot_offset = node.size / 2
    _trans_in(node, 'scale', orig_scale*3.0*ext, orig_scale*ext, dur, time)

func scale_inv_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset = node.size / 2
    var orig_scale = _get_orig(node, 'scale')
    _trans_out(node, 'scale', orig_scale*ext, Vector2.ZERO, dur, time)
func scale_x_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset.x = node.size.x / 2
    var orig_scale = _get_orig(node, 'scale:x')
    _trans_in(node, 'scale:x', 0, orig_scale*ext, dur, time)

func scale_x_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset.x = node.size.x / 2
    var orig_scale = _get_orig(node, 'scale:x')
    _trans_out(node, 'scale:x', null, orig_scale*3.0*ext, dur, time)

func scale_x_inv_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset.x = node.size.x / 2
    var orig_scale = _get_orig(node, 'scale:x')
    _trans_in(node, 'scale:x', orig_scale*3.0*ext, orig_scale*ext, dur, time)

func scale_x_inv_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset.x = node.size.x / 2
    var orig_scale = _get_orig(node, 'scale:x')
    _trans_out(node, 'scale:x', null, 0, dur, time)

func scale_y_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset.y = node.size.y / 2
    var orig_scale = _get_orig(node, 'scale:y')
    _trans_in(node, 'scale:y', 0, orig_scale*ext, dur, time)

func scale_y_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset.y = node.size.y / 2
    var orig_scale = _get_orig(node, 'scale:y')
    _trans_out(node, 'scale:y', null, orig_scale*3*ext, dur, time)
func scale_y_inv_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset.y = node.size.y / 2
    var orig_scale = _get_orig(node, 'scale:y')
    _trans_in(node, 'scale:y', orig_scale*3.0*ext, orig_scale*ext, dur, time)

func scale_y_inv_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if 'pivot_offset' in node:
        node.pivot_offset.y = node.size.y / 2
    var orig_scale = _get_orig(node, 'scale:y')
    _trans_out(node, 'scale:y', null, 0, dur, time)
# --------------------
func off_x_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if not 'offset_left' in node: return
    var orig_pos = _get_orig(node, 'offset_left')
    _trans_in(node, 'offset_left', orig_pos-50*ext, orig_pos, dur, time)
func off_x_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if not 'offset_left' in node: return
    var orig_pos = _get_orig(node, 'offset_left')
    _trans_out(node, 'offset_left', null, orig_pos+50*ext, dur, time)

func off_x_inv_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if not 'offset_left' in node: return
    var orig_pos = _get_orig(node, 'offset_left')
    _trans_in(node, 'offset_left', orig_pos+50*ext, orig_pos, dur, time)
func off_x_inv_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if not 'offset_left' in node: return
    var orig_pos = _get_orig(node, 'offset_left')
    _trans_out(node, 'offset_left', null, orig_pos-50*ext, dur, time)
#-------------------
func pos_x_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var orig_pos = _get_orig(node, 'position:x')
    _trans_in(node, 'position:x', orig_pos-50.0*ext, orig_pos, dur, time)

func pos_x_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var orig_pos = _get_orig(node, 'position:x')
    _trans_out(node, 'position:x', null, orig_pos+50.0*ext, dur, time)

func pos_x_inv_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var orig_pos = _get_orig(node, 'position:x')
    _trans_in(node, 'position:x', orig_pos+50.0*ext, orig_pos, dur, time)

func pos_x_inv_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var orig_pos = _get_orig(node, 'position:x')
    _trans_out(node, 'position:x', null, orig_pos-50.0*ext, dur, time)
# --------------------
func off_y_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if not 'offset_top' in node: return
    var orig_pos = _get_orig(node, 'offset_top')
    _trans_in(node, 'offset_top', orig_pos-50*ext, orig_pos, dur, time)
func off_y_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if not 'offset_top' in node: return
    var orig_pos = _get_orig(node, 'offset_top')
    _trans_out(node, 'offset_top', null, orig_pos+50*ext, dur, time)

func off_y_inv_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if not 'offset_top' in node: return
    var orig_pos = _get_orig(node, 'offset_top')
    _trans_in(node, 'offset_top', orig_pos+50*ext, orig_pos, dur, time)
func off_y_inv_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    if not 'offset_top' in node: return
    var orig_pos = _get_orig(node, 'offset_top')
    _trans_out(node, 'offset_top', null, orig_pos-50*ext, dur, time)
#-------------------
func pos_y_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var orig_pos = _get_orig(node, 'position:y')
    _trans_in(node, 'position:y', orig_pos-50.0*ext, orig_pos, dur, time)

func pos_y_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var orig_pos = _get_orig(node, 'position:y')
    _trans_out(node, 'position:y', null, orig_pos+50.0*ext, dur, time)

func pos_y_inv_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var orig_pos = _get_orig(node, 'position:y')
    _trans_in(node, 'position:y', orig_pos+50.0*ext, orig_pos, dur, time)

func pos_y_inv_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var orig_pos = _get_orig(node, 'position:y')
    _trans_out(node, 'position:y', null, orig_pos-50.0*ext, dur, time)
#-------------------
func color_in(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var k = _get_color_key(node)
    var orig = _get_origin_color(node)
    _trans_in(node, k, color_roll(orig, {'H':-0.3*ext, 'V':-0.2*ext}), orig, dur, time)
func color_out(node:Node, time:float=0.0, dur:float=0.0, ext=1.0):
    var k = _get_color_key(node)
    var orig = _get_origin_color(node)
    _trans_out(node, k, null, color_roll(orig, {'H':0.3*ext, 'V':0.2}), dur, time)

func _get_color_key(node):
    if node is Label:
        return 'theme_override_colors/font_color'
    elif node is RichTextLabel:
        return 'theme_override_colors/default_color'
    elif 'color' in node:
        return 'color'
    else:
        return 'modulate'
func _get_origin_color(node):
    if node.has_meta('orig_color'): return node.get_meta('orig_color')
    
    var color = 'FFFFFF'
    if node is Label:
        color = UI.get_font_color(node)
    elif node is RichTextLabel:
        color = UI.get_font_color(node)
    elif 'color' in node:
        color = node.color
    else:
        color = node.modulate
    node.set_meta('orig_color', color)
    return color

# ------------------------------------
func set_opacity(node, alpha):
    if 'color' in node:
        node.color.a = alpha
    elif 'default_color' in node:
        node.default_color.a = alpha
    else:
        node.modulate.a = alpha

func get_opacity(node):
    if 'color' in node:
        return node.color.a
    elif 'default_color' in node:
        return node.default_color.a
    else:
        return node.modulate.a

func set_color(node, clr):
    if 'color' in node:
        node.color = clr
    elif 'default_color' in node:
        node.default_color = clr
    else:
        node.modulate = clr

func get_color(node):
    if 'color' in node:
        return node.color
    elif 'default_color' in node:
        return node.default_color
    else:
        return node.modulate
# ------------------------------------
func blink_in(node:Node, time:float=0.0, dur:float=0.0):
    # fade-white-orig
    var prop = _get_color_key(node)
    var color_fade = Color('FFFFFF00')
    var color_white = Color('FFFFFF')
    var color_origin = Color(_get_origin_color(node))

    if dur == 0.0: dur = 0.15
    node.show()
    node.set_indexed(prop, color_fade)
    print('node', node.get_indexed(prop))
    var twn = node.create_tween()
    twn.tween_interval(time)
    twn.tween_property(node, prop, color_white, dur * 0.7)
    twn.tween_interval(dur*0.6)
    twn.tween_property(node, prop, color_origin, dur * 0.7)

func blink_out(node:Node, time:float=0.0, dur:float=0.0):
    # orig-white-fade
    var prop = _get_color_key(node)
    var color_fade = Color('FFFFFF00')
    var color_white = Color('FFFFFF')

    if dur == 0.0: dur = 0.15
    node.show()
    node.modulate.a = 1.0
    var twn = node.create_tween()
    twn.tween_interval(time)
    twn.tween_property(node, prop, color_white, dur * 0.7)
    twn.tween_interval(dur*0.6)
    twn.tween_property(node, prop, color_fade, dur * 0.7)
    twn.tween_callback(node.hide)

func typing_in(node, delay=0.0, speed=50.0, callback=null):
    if not (node is Label or node is RichTextLabel): return
    var t_len = node.text.length() + 1.0
    var dur = t_len / speed
    _trans_in_no_fade(node, 'visible_ratio', 0.0, 1.0, dur, delay)

func typing_out(node, delay=0.0, speed=50.0, callback=null):
    if not (node is Label or node is RichTextLabel): return
    var t_len = node.text.length() + 1.0
    var dur = t_len / speed
    _trans_out_no_fade(node, 'visible_ratio', 1.0, 0.0, dur, delay)

func blink(node:Node, time:float=0.2):
    await wait(time)
    if is_valid(node): shade(node, 'res://assets/shaders/blink.gdshader')
    await wait(0.25)
    if is_valid(node): unshade(node)

func shake(node:Node, time:float=0.0):
    var tn = TwnMisc.new()
    tn.target = node
    node.set_meta('twn_misc', tn)
    TwnLite.at(node)\
           .follow({call=tn._follow_shake})

func outline(node:Node):
    shade(node, 'res://temp/shaders/outline.gdshader', {outline_color=Color('Ffffff')})
# --------------------------
# class OffViewport extends SubViewport:
#     func _init():
#         transparent_bg = true
#         disable_3d = true
#         gui_disable_input = true
#         own_world_3d = true
# --------------------------
func get_offviewport(vwsize):
    var vp = SubViewport.new()
    vp.transparent_bg = true
    vp.disable_3d = true
    vp.gui_disable_input = true
    vp.canvas_item_default_texture_filter = SubViewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
    # vp.own_world_3d = true
    vp.size = vwsize
    add_child(vp)
    return vp

func get_texture(tex):
    if tex is Texture:
        return tex
    elif tex is String:
        if tex.begins_with('res://'):
            return load(tex)
        else:
            return load("res://assets/textures/%s.png" % tex)
    else:
        printerr('texture not valid', tex)
        return null

func get_material(mat):
    if mat is Material:
        return mat
    elif mat is String:
        if mat.left(6) == 'res://':
            return load(mat)
        else:
            return load("res://assets/materials/%s.tres" % mat)
    else:
        printerr('material not valid', mat)
        return null

# func get_shader(mat):
#     if mat is Shader:
#         return mat
#     elif mat is String:
#         if mat.left(6) == 'res://':
#             return load(mat)
#         else:
#             return load("res://assets/shaders/%s.gdshader" % mat)
#     else:
#         printerr('shader not valid', mat)
#         return null

# func get_shader_material(mat):
#     if mat is ShaderMaterial:
#         return mat
#     elif mat is String:
#         if mat.left(6) == 'res://':
#             var ret = ShaderMaterial.new()
#             ret.shader = load(mat)
#             return ret
#         else:
#             var conf = Raw.load(mat, true)
#             if conf == null: return null
#             if conf.has('material'):
#                 mat = get_material(conf.material)
