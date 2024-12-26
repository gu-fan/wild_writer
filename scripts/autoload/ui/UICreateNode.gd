class_name UICreateNode

# Create Node Misc
static func get_node_conf_from_raw(raw, params={}):
    var conf = Raw.load(raw)
    if params: conf.merge(params, true)
    var p = conf.get('parent')
    var n = conf.get('name')
    if n == null:  # in case it named '0'
        n = raw.split(':')[1]
        conf.name = n
    return conf

static func get_parent_from_raw(raw, params={}, _internal_mode=0):
    # first from params, second from raw
    var conf = Raw.load(raw)
    if params: conf.merge(params, true)
    var p = conf.get('parent')
    if p is String: p = UI._get_ui_node_from_string(p)
    return p

static func get_name_from_raw(raw, params={}, _internal_mode=0):
    # first from params, second from raw split
    var conf = Raw.load(raw)
    if params: conf.merge(params, true)
    var n = conf.get('name')
    if n == null: n = raw.split(':')[1]
    return n

# Create Node
static func get_or_create_node_from_raw(raw, params={}, _internal_mode=0):
    var conf = get_node_conf_from_raw(raw, params)
    return get_or_create_node(conf, _internal_mode)

static func get_node_or_null_from_raw(raw, params={}, _internal_mode=0):
    var conf = get_node_conf_from_raw(raw, params)
    return get_node_or_null_from_dic(conf, _internal_mode)

static func create_node_from_raw(raw, params={}, _internal_mode=0):
    var conf = get_node_conf_from_raw(raw, params)
    return create_node(conf, _internal_mode)

static func get_node_or_null_from_dic(params:Dictionary={}, _internal_mode=0)->Node:
    var p = params.get('parent')
    var n = params.get('name')
    if p and n:
        if p.has_node(n):
            return p.get_node(n)
    return null

static func get_or_create_node(params:Dictionary={}, _internal_mode=0)->Node:
    var p = params.get('parent')
    var n = params.get('name')
    if p and n:
        if p.has_node(n):
            return p.get_node(n)
    return create_node(params, _internal_mode)

static func create_node(params:Dictionary={}, _internal_mode=0)->Node:
    params = params.duplicate(true)

    var type = params.get('type')
    if type == null: 
        printerr('invalid null type', params)
        return
    var _nd

    # load base config and rewrite some property
    if type is String and type.left(3) == 'UI/': # 'UI/component:btn_rect_confirm'
        var conf = Raw.load(type)
        type = conf.get('type')
        params.merge(conf)

    if type is String:
        # load Script Defined Class
        if type.left(1) == '@': # '@ui/RectButton'
            var scp = 'res://scripts/' +  type.substr(1) + '.gd'
            _nd = load(scp).new()
        elif type.begins_with('res:') and type.ends_with('.tscn'):
            _nd = load(type).instantiate()
        else:
            # load Base Component
            _nd = ClassDB.instantiate(type)
    else:
        # Try load direct from type
        _nd = type.new()

    __setup_nd_default(_nd, type)

    if params.has('preset') or params.has('pre_offset'): 
        var preset = params.get('preset', UILayout.PRESET_TOP_LEFT)
        var offset = params.get('pre_offset', Vector2.ZERO)
        UILayout.set_layout(_nd, preset, offset)
        Util.erase_keys(params, ['preset','pre_offset'])

    if params.has('name'): _nd.name = params.name

    if params.has('internal_mode'):
        _internal_mode = params.internal_mode
    
    # UI: need thinking
    # set ignore as default
    if params.has('patterns'):
        # ready is after entertree, so all the size is set
        _nd.ready.connect(UI.set_patterns.bind(_nd, params.patterns), CONNECT_ONE_SHOT)

    if params.has('trans_in'):
        _nd.ready.connect(
            UI.trans_in.bind(_nd, params.trans_in)
        )
    if params.has('transition'):
        _nd.set_meta('transition', params.transition)
    if params.has('transition_in'):
        _nd.set_meta('transition_in', params.transition_in)
    if params.has('transition_out'):
        _nd.set_meta('transition_out', params.transition_out)

    if params.has('font'): # NOTE: should set before size
        UI.set_font(_nd, params.font)

    if params.has('meta'): # Meta should be Dictionary
        for k in params.meta:
            _nd.set_meta(k, params.meta[k])

    Util.erase_keys(params, ['name', 'type', 'internal_mode', 'patterns', 'trans_out', 'trans_in',
                            'transition', 'transition_in', 'transition_out', 'font', 'meta', 'modal'])

    for k in params:
        if k in ['parent', 'child', 'children', 'child_repeat', 'child_params']: continue
        if UISetNode.UI_SETUP_PROPS.has(k):
            var _call = Callable(UISetNode, 'set_' + k)
            _call.call(_nd, params[k])
        elif k.left(3) == 'on_':
            __connect_node_params(_nd, k, params[k])
        elif k.left(7) == 'sig_on_':
            __connect_node_signal(_nd, k, params[k])
        else:
            if k in _nd:
                _nd.set(k, params[k])
            else:
                printerr('param %s not in node' % k, params)

    if params.has('child'):
        __create_node_child(_nd, params)

    if params.has('children'):
        __create_node_children(_nd, params)

    # NOTE: set parent after all param and child is set, 
    # so these child exists when parent ready
    if params.has('parent'):
        var _par = params.parent
        if _par is String:
            _par = UI._get_ui_node_from_string(_par)

        if _par:
            if _internal_mode:
                _par.add_child(_nd, false, _internal_mode)
            else:
                _par.add_child(_nd)

    return _nd

static func __setup_nd_default(nd, type):
    if type is String:
        if type.right(6) != 'Button' and type.left(5) != 'Panel' and type != 'LineEdit' and 'mouse_filter' in nd:
            nd.mouse_filter = UI.MOUSE_FILTER_IGNORE
        if type == 'Button': 
            nd.focus_mode = Button.FOCUS_NONE

static func __create_node_child(nd, params):
    var child = params.child
    var chd_params = params.get('child_params')
    if child is String: child = Raw.load(child)

    if params.has('child_repeat'):
        for i in params.child_repeat:
            var chd = child.duplicate()
            if chd.has('name'): chd.name = chd.name + str(i)
            chd.parent = nd
            if chd_params: chd.merge(chd_params, true)
            create_node(chd)
    else:
        var chd = child.duplicate()
        chd.parent = nd
        if chd_params: chd.merge(chd_params, true)
        create_node(chd)  # use create_node not add_child, so internal mode can be altered in child config

static func __create_node_children(nd, params):
    var chd_params = params.get('child_params')
    if params.children is Dictionary:
        for k in params.children:
            var child = params.children[k]
            if child is String: child = Raw.load(child)
            var chd = child.duplicate()
            chd.parent = nd
            chd.name = k
            if chd_params: chd.merge(chd_params, true)
            create_node(chd)
    else: # Array
        for child in params.children:
            if child is String: child = Raw.load(child)
            var chd = child.duplicate()
            chd.parent = nd
            if chd_params: chd.merge(chd_params, true)
            create_node(chd)

static func __connect_node_signal(nd, k, val):
    # TODO: need a new global signal emitter
    printerr('Not Implemented:__connect_node_signal')

static func __connect_node_params(nd, k, val):
    if val is Callable:
        nd.connect(k.substr(3), val)
    elif val is String:  # use the method in ui, not on node
        # on_ready = 'debug_rect' / 'print_pos' / ...
        var prms = Array(val.split(':'))
        var mth = prms.pop_front()
        var args = prms
        for i in args.size():
            var arg = args[i]
            if arg is String and arg == 'self': args[i] = nd
        if args.is_empty():
            nd.connect(k.substr(3), UI.call.bind(mth))
        else:
            nd.connect(k.substr(3), UI.callv.bind(mth, args))
    elif val is Dictionary: # use method on node
        var _n = val.get('node', 'Util')
        if _n: _n = UI.get_tree().root.get_node(_n)

        var mth = val.get('method')
        var args = val.get('args')
        for i in args.size():
            var arg = args[i]
            if arg is String and arg == 'self': args[i] = nd
        if args:
            nd.connect(k.substr(3), _n.callv.bind(mth, args))
        else:
            nd.connect(k.substr(3), _n.call.bind(mth)) 
