class_name TwnLite extends Tween
## 简化的补间动画工具类
## v1.02

const DEFAULT_DURATION := 0.3

var _bind_node: Node

## 创建一个新的补间实例
## [param node] 绑定的节点
## [param refresh] 是否刷新已存在的补间
## [param id] 补间标识符
## [return] 补间实例
static func at(node: Node, refresh: bool = true, id: String = '_twn_lite') -> TwnLite:
    var twn := node.create_tween()
    twn.script = TwnLite
    twn._bind_node = node

    if refresh and node.has_meta(id):
        var prev = node.get_meta(id)
        prev.kill()

    node.set_meta(id, twn)
    return twn

## 停止指定节点的补间动画
static func off(node: Node, id: String = '_twn_lite') -> void:
    if node.has_meta(id):
        var prev = node.get_meta(id)
        prev.kill()

## 创建属性补间
## [param params] 补间参数字典
## [return] 补间实例
func tween(params: Dictionary = {}) -> TwnLite:
    var target = params.get('target', _bind_node)
    var prop: String = params.get('prop', '')
    var to = params.get('to')
    
    if to is String and prop in ['modulate', 'color']:
        to = Color(to)
    
    var dur = params.get('dur', DEFAULT_DURATION)
    
    if params.has('parallel'):
        set_parallel(params.parallel)

    var t := tween_property(target, prop, to, dur)

    if params.has('from'): t.from(params.from)
    if params.get('from_current', false): t.from_current()
    if params.get('as_relative', false): t.as_relative()
    if params.has('delay'): t.set_delay(params.delay)
    if params.has('ease'): t.set_ease(params.ease)
    if params.has('trans'): t.set_trans(params.trans)
    if params.has('inter'): t.set_custom_interpolator(params.inter)
    elif params.has('curve'): t.set_custom_interpolator(_use_curve.bind(params.curve))

    return self

## 创建回调补间
## [param params] 回调参数字典或可调用对象
## [return] 补间实例
func callee(params = {}) -> TwnLite:
    if params is Callable:
        params = {call = params}

    var method: Callable = params.get('call', Callable())
    var args: Array = params.get('args', [])
    var target: Node = params.get('target', _bind_node)

    if params.has('parallel'):
        set_parallel(params.parallel)

    var t: CallbackTweener
    if method.is_valid():
        t = tween_callback(method.bindv(args) if not args.is_empty() else method)
    else:
        var method_name: String = params.get('method', '')
        t = tween_callback(
            Callable(target, method_name).bindv(args) if not args.is_empty() 
            else Callable(target, method_name)
        )


    if params.has('delay'):
        t.set_delay(params.delay)

    return self

## 创建方法补间
## [param params] 方法参数字典
## [return] 补间实例
func follow(params: Dictionary = {}) -> TwnLite:
    var method = params.get('call')
    var args = params.get('args', [])
    var from = params.get('from', 0.0)
    var to = params.get('to', 1.0)
    var dur = params.get('dur', DEFAULT_DURATION)

    if params.has('parallel'):
        set_parallel(params.parallel)

    var t: MethodTweener
    if method is Callable:
        t = tween_method(method.bindv(args) if not args.is_empty() 
            else method, from, to, dur)
    else:
        var target = params.get('target', _bind_node)
        t = tween_method(
            Callable(target, method).bindv(args) if not args.is_empty() 
            else Callable(target, method), from, to, dur)

    if params.has('delay'): t.set_delay(params.delay)
    if params.has('trans'): t.set_trans(params.trans)
    if params.has('ease'): t.set_ease(params.ease)
    
    return self

## 创建着色器参数补间
## [param params] 着色器参数字典
## [return] 补间实例
func shade(params: Dictionary = {}) -> TwnLite:
    var target = params.get('target', _bind_node)
    var prop: String = params.get('prop', '')
    var to = params.get('to')
    var from = params.get('from')
    var dur = params.get('dur', DEFAULT_DURATION)
    
    if to is String and prop in ['modulate', 'color']: 
        to = Color(to)
    if from is String and prop in ['modulate', 'color']: 
        from = Color(from)
    
    if params.has('parallel'):
        set_parallel(params.parallel)
        
    var t := tween_method(_shade_params.bind(target, prop), from, to, dur)
    
    if params.has('delay'): t.set_delay(params.delay)
    if params.has('trans'): t.set_trans(params.trans)
    if params.has('ease'): t.set_ease(params.ease)
    
    return self

## 设置着色器参数
func _shade_params(val, target: Node, key: String) -> void:
    target.material.set_shader_parameter(key, val)

## 设置循环次数
func repeat(i: int) -> TwnLite:
    set_loops(i)
    return self

## 设置循环次数（别名）
func loop(i: int) -> TwnLite:
    set_loops(i)
    return self

## 添加延迟
func delay(t: float) -> TwnLite:
    # chain()
    set_parallel(false)
    tween_interval(t)
    return self

func wait(t: float) -> TwnLite:
    # chain()
    set_parallel(false)
    tween_interval(t)
    return self
func off_parallel():
    chain()
    set_parallel(false)
    return self

## 使用曲线进行插值
func _use_curve(v: float, c: Curve) -> float:
    return c.sample_baked(v)

## 队列执行多个补间
## [param qs] 补间队列
## [param _shifts] 补间参数修改
## [return] 补间实例
func queue(qs: Array, _shifts: Dictionary = {}) -> TwnLite:
    qs = qs.duplicate(true)
    if not _shifts.is_empty():
        for q in qs:
            _alter_qs(q, _shifts)

    for qu in qs:
        if qu.has('prop'):
            tween(qu)
        elif qu.has('call'):
            if qu.has('to'):
                follow(qu)
            else:
                callee(qu)
        elif qu.has('delay'):
            delay(qu.delay)
        elif qu.has('trans'):
            set_trans(qu.trans)
        elif qu.has('ease'):
            set_ease(qu.ease)
        elif qu.has('parallel'):
            parallel()
    return self

## 修改补间参数
func _alter_qs(q: Dictionary, _shifts: Dictionary) -> void:
    if q.has('prop'):
        var s = q.prop
        if _shifts.has(s):
            var sft = _shifts[s]
            var _from = q.get('from')
            var _to = q.to
            var _d = float(sft.substr(1))
            if sft.begins_with('*'):
                _to *= _d
                if _from != null: _from *= _d
            elif sft.begins_with('+'):
                _to += _d
                if _from != null: _from += _d
            elif sft.begins_with('-'):
                _to -= _d
                if _from != null: _from -= _d
            q.to = _to
            if _from != null: q.from = _from
            
    if _shifts.has('speed_scale'):
        var spd = float(_shifts.speed_scale)
        if q.has('dur'): q.dur = q.dur / spd
        if q.has('delay'): q.delay = q.delay / spd

## 条件执行补间
func tween_if(check: bool, params: Dictionary) -> TwnLite:
    return tween(params) if check else self

## 条件执行回调
func callee_if(check: bool, params) -> TwnLite:
    return callee(params) if check else self

## 条件执行方法补间
func follow_if(check: bool, params: Dictionary) -> TwnLite:
    return follow(params) if check else self

## 条件执行延迟
func delay_if(check: bool, t: float) -> TwnLite:
    return delay(t) if check else self

## 条件执行延迟（别名）
func wait_if(check: bool, t: float) -> TwnLite:
    return delay(t) if check else self

## 条件执行着色器补间
func shade_if(check: bool, params: Dictionary) -> TwnLite:
    return shade(params) if check else self

# ----------------------------------------------
