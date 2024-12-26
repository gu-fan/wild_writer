class_name UISetNode

# Setup Node Properties
const UI_SETUP_PROPS = {
    'opacity':1, 
    'color':1,
    'bg_color':1,
    'flat_style':1,
    'font':1,  # set before size, but need here in Vfx.text
    'font_size':1,
    'font_color':1, 
    'font_shadow_color':1,
    'font_outline_color':1,
    'font_outline_size':1,
    'font_shadow_size':1,
    'separation':1,
    'image':1,
    'shade':1,
    'shadow':1,
}

static func set_font(_nd:Node, font_path):
    # font_path: dictionary / font res path / font
    var font
    var rich_font
    var btn_font
    var font_size
    var font_color
    var params = {}
    if font_path is Dictionary:
        params = font_path
        font_size = params.size
        font_color = params.get('color')
        rich_font = params.get('rich')
        btn_font = params.get('btn')
        font_path = params.font
        if rich_font and rich_font is String:
            rich_font = load(rich_font)
        if btn_font and btn_font is String:
            btn_font = load(btn_font)
    
    if font_path is String:
        font = load(font_path)
    else:
        font = font_path

    if _nd is RichTextLabel:
        if rich_font: font = rich_font
        _nd.set("theme_override_fonts/normal_font", font)
    elif _nd is Button:
        if btn_font: font = btn_font
        _nd.set("theme_override_fonts/font", font)
    else:
        _nd.set("theme_override_fonts/font", font)

    if font_size: set_font_size(_nd, font_size)
    if font_color: set_font_color(_nd, font_color)

static func set_font_size(_nd:Node, font_size:float):
    if _nd is RichTextLabel:
        _nd.set("theme_override_font_sizes/normal_font_size", font_size)
    else:
        _nd.set("theme_override_font_sizes/font_size", font_size)

static func set_font_color(_nd:Node, color):
    if _nd is RichTextLabel:
        _nd.set("theme_override_colors/default_color", Color(color))
    else:
        _nd.set("theme_override_colors/font_color", Color(color))

static func set_font_shadow_color(_nd:Node, color):
    _nd.set("theme_override_colors/font_shadow_color", Color(color))

static func set_font_outline_color(_nd:Node, color):
    _nd.set("theme_override_colors/font_outline_color", Color(color))

static func set_font_shadow_size(_nd:Node, _size:Variant):
    if _size is Vector2:
        _nd.set("theme_override_constants/shadow_offset_x", _size.x)
        _nd.set("theme_override_constants/shadow_offset_y", _size.y)
    else:
        _nd.set("theme_override_constants/shadow_offset_x", _size)
        _nd.set("theme_override_constants/shadow_offset_y", _size)

static func set_font_outline_size(_nd:Node, _size:int):
    _nd.set("theme_override_constants/outline_size", _size)

static func set_separation(_nd, val):
    if _nd is GridContainer:
        _nd.set('theme_override_constants/h_separation', val)
        _nd.set('theme_override_constants/v_separation', val)
    elif _nd is HBoxContainer or _nd is VBoxContainer:
        _nd.set('theme_override_constants/separation', val)
    else:
        if 'separation' in _nd:
            _nd.separation = val

static func set_opacity(_nd:Node, val:float):
    if 'color' in _nd:
        _nd.color.a = val
    else:
        _nd.modulate.a = val

static func set_color(_nd:Node, val:String):
    if 'color' in _nd:
        _nd.color = Color(val)
    elif _nd is Label or _nd is RichTextLabel:
        set_font_color(_nd, val)
    elif _nd is Control or _nd is Panel:
        # don't set color of these
        pass
    else:
        _nd.modulate = Color(val)

static func set_shadow(_nd:Node, val):
    var offset
    var color = '000000'
    if val is int or val is float:
        offset = Vector2(val, val)
    elif val is Vector2 or val is Vector2i:
        offset = val
    elif val is Dictionary:
        offset = val.get('offset', Vector2i.ZERO)
        color = val.get('color', color)

    var rect = ColorRect.new()
    rect.color = color
    rect.position = offset
    rect.show_behind_parent = true
    rect.mouse_filter = UI.MOUSE_FILTER_IGNORE
    _nd.add_child(rect)
    _nd.ready.connect(func():
        rect.custom_minimum_size = _nd.size
    )

static func set_shade(_nd:Node, _shd):
    if _shd is Dictionary:
        Util.shade(_nd, _shd.shader, _shd.params)
    else:
        Util.shade(_nd, _shd)

static func set_image(_nd:Node, img_data):
    if img_data is String:
        img_data = Raw.load(img_data)
        
    if img_data is Array:
        img_data = Rnd.pick(img_data) # for random pick images
    if _nd is Sprite2D:
        Spr.set_sprite(_nd, img_data)
    elif _nd is TextureRect:
        Spr.set_tex_rect(_nd, img_data)
    else:
        printerr('Invalid node type:', _nd)


static func set_bg_color(_nd:Node, val:String):
    if _nd.get_class() in ['Label', 'RichTextLabel', 'Panel']:
        var params = {bg_color=val}
        set_flat_style(_nd, params)

static func set_flat_style(_nd, params={}):
    var cls = _nd.get_class()
    if !params.has('border_width'):
        if cls == 'Label':
            params.border_width = 0
        else:
            params.border_width = 1
    var new_style = get_flat_style(params)
    match cls:
        'Panel', 'PanelContainer', 'ScrollContainer':
            _nd.set("theme_override_styles/panel", new_style)
        'Label':
            _nd.set("theme_override_styles/normal", new_style)
        'Button':
            _nd.set("theme_override_styles/hover", new_style)
            _nd.set("theme_override_styles/pressed", new_style)
            _nd.set("theme_override_styles/focus", new_style)
            _nd.set("theme_override_styles/disabled", new_style)
            _nd.set("theme_override_styles/normal", new_style)

static func get_flat_style(params={}):
    var style = StyleBoxFlat.new()
    style.anti_aliasing = false
    style.bg_color = params.get('bg_color', G.COLOR_UI_BG)

    var expand_margin = params.get('expand_margin')
    if expand_margin:
        if expand_margin is Dictionary:
            style.expand_margin_left = expand_margin.left
            style.expand_margin_right = expand_margin.right
            style.expand_margin_top = expand_margin.top
            style.expand_margin_bottom = expand_margin.bottom
        else:
            style.expand_margin_left = expand_margin
            style.expand_margin_right = expand_margin
            style.expand_margin_top = expand_margin
            style.expand_margin_bottom = expand_margin

    var content_margin = params.get('content_margin')
    if content_margin:
        if content_margin is Dictionary:
            style.content_margin_left = content_margin.left
            style.content_margin_right = content_margin.right
            style.content_margin_top = content_margin.top
            style.content_margin_bottom = content_margin.bottom
        else:
            style.content_margin_left = content_margin
            style.content_margin_right = content_margin
            style.content_margin_top = content_margin
            style.content_margin_bottom = content_margin

    var border_width = params.get('border_width', 1)
    if border_width:
        style.border_width_left = border_width
        style.border_width_right = border_width
        style.border_width_top = border_width
        style.border_width_bottom = border_width
        style.border_color = params.get('border_color', G.COLOR_UI_BORDER)

    return style
static func get_font_color(_nd:Node):
    if _nd is RichTextLabel:
        var clr = _nd.get("theme_override_colors/default_color")
        if clr == null:
            clr = ThemeDB.get_default_theme().get_color('default_color', 'RichTextLabel')
        return clr
    elif _nd is Label:
        var clr = _nd.get("theme_override_colors/font_color")
        if clr == null:
            clr = ThemeDB.get_default_theme().get_color('font_color', 'Label')
        return clr
    #elif _nd is RectButton:
        #return get_font_color(_nd.lb)
    elif _nd is Button:
        var clr = _nd.get("theme_override_colors/font_color")
        if clr == null:
            clr = ThemeDB.get_default_theme().get_color('font_color', 'Button')
        return clr
    else:
        var clr = _nd.get("theme_override_colors/font_color")
        if clr == null:
            # XXX: this is not correct, get_class() is not class_name
            clr = ThemeDB.get_default_theme().get_color('font_color', _nd.get_class())
        return clr


# ---------------------------------
# PATTERN: DEPRECATED?
const _ptn_poses = [Vector2(0,0), Vector2(1,0),Vector2(1,1),Vector2(0,1)]
# 8, 8
## can not use 'control' and preset, as it will not taken effect on 'Container' (Hint/TinyHint)
static func set_corner_pattern(nd, _ptn='corner_s0',dir=[1,1,1,1], color='FFFFFF'):
    for p in 4:
        if dir[p]:
            var ptn = _ptn + '_' + str(p)
            var icon = Raw.load('UI/pattern:' + ptn)
            var spr = Spr.create(icon)
            spr.name = 'CORNER_' + str(p)
            spr.position.x = _ptn_poses[p].x * (nd.size.x - icon.frame_size.x)
            spr.position.y = _ptn_poses[p].y * (nd.size.y - icon.frame_size.y)
            spr.modulate = color
            nd.add_child(spr, false, 1)
            nd.resized.connect(func():
                spr.position.x = _ptn_poses[p].x * (nd.size.x - icon.frame_size.x)
                spr.position.y = _ptn_poses[p].y * (nd.size.y - icon.frame_size.y)
            )

# 32, 8
static func set_border_pattern(nd, _ptn='top0', dir=[1,0,0,0], color='FFFFFF'):
    var icon = Raw.load('UI/pattern:' + _ptn)
    var size
    if icon.frame_size is Array:
        size = Vector2(icon.frame_size[0], icon.frame_size[1])
    else:
        size = icon.frame_size
    for p in 4:
        if dir[p]:
            var spr = Spr.create(icon)
            spr.name = 'BORDER_' + str(p)
            match p:
                0:
                    spr.position.x = int(nd.size.x / 2 - size.x / 2)
                    spr.position.y = 0
                1:
                    spr.position.x = nd.size.x
                    spr.position.y = int(nd.size.y / 2 - size.x / 2)
                    spr.rotation = PI/2
                2:
                    spr.position.x = int(nd.size.x / 2 - size.x / 2)
                    spr.position.y = nd.size.y - size.y
                    spr.flip_v = true
                3:
                    spr.position.x = 0
                    spr.position.y = int(nd.size.y / 2 + size.x / 2)
                    spr.rotation = PI*3/2

            spr.modulate = color
            nd.add_child(spr, false, 1)
            nd.resized.connect(func():
                match p:
                    0:
                        spr.position.x = int(nd.size.x / 2 - size.x / 2)
                        spr.position.y = 0
                    1:
                        spr.position.x = nd.size.x
                        spr.position.y = int(nd.size.y / 2 - size.x / 2)
                        spr.rotation = PI/2
                    2:
                        spr.position.x = int(nd.size.x / 2 - size.x / 2)
                        spr.position.y = nd.size.y - size.y
                        spr.flip_v = true
                    3:
                        spr.position.x = 0
                        spr.position.y = int(nd.size.y / 2 + size.x / 2)
                        spr.rotation = PI*3/2
            )

static func set_pattern(nd, _ptn, pos=Vector2i.ZERO, color='FFFFFF'):
    var icon = Raw.load('UI/pattern:' + _ptn)
    var spr = Spr.create(icon)
    spr.name = 'PTN_' + _ptn
    nd.add_child(spr, false, 1)
    spr.modulate = color
    if pos: spr.position = pos
    return spr

static func set_patterns(nd, ptns): # this is connect with nd ready
    #await wait(0.01)
    var color = ptns.get('color', G.COLOR_UI_BORDER)
    ptns.erase('color')
    for ptn in ptns:
        var value = ptns[ptn]
        if ptn.left(6) == 'corner':
            set_corner_pattern(nd, ptn, value, color)
        elif ptn.left(6) == 'border':
            set_border_pattern(nd, ptn, value, color)
        else:
            set_pattern(nd, ptn, value, color)
