class_name Spr
# v1.0


static func get_coord_rect(sprite) -> Rect2:
    var size = sprite.texture.get_size()
    var _tex_rect
    if sprite.region_enabled:
        _tex_rect = sprite.region_rect
    else:
        _tex_rect = Rect2(Vector2.ZERO, size)

    var hlen = _tex_rect.size.x / sprite.hframes
    var vlen = _tex_rect.size.y / sprite.vframes

    var coords = sprite.frame_coords
    var rsize = Vector2(hlen, vlen)
    var rpos = _tex_rect.position  + Vector2(coords.x*hlen, coords.y*vlen)
    return Rect2(rpos, rsize)

static func clip_rect(spr, rect, _clip_clr=''):
    var src_img = spr.texture.get_image()
    var src_size = src_img.get_size()
    var clip_clr = Color(_clip_clr) if _clip_clr else Color(0,0,0,0)
    for i in rect.size.x:
        var _x = i + rect.position.x
        if _x > src_size.x or _x < 0: continue
        for j in rect.size.y:
            var _y = j + rect.position.y
            if _y > src_size.y or _y < 0: continue
            src_img.set_pixel(_x, _y, clip_clr)
    spr.texture = ImageTexture.create_from_image(src_img)

static func clip_rect_mask(spr, rect, _clip_clr=''):
    # a bit faster than clip by pixel, about 1% - 5%
    var src_img = spr.texture.get_image()
    var src_size = src_img.get_size()
    var empty_img = Image.create_empty(src_size.x, src_size.y, false,Image.FORMAT_RGBA8)
    var msk_img = Image.create_empty(src_size.x, src_size.y, false, Image.FORMAT_RGBA8)
    msk_img.fill_rect(rect, Color(0,0,0,1))
    src_img.blit_rect_mask(empty_img, msk_img, Rect2i(0,0,src_size.x,src_size.y), Vector2i.ZERO)

    spr.texture = ImageTexture.create_from_image(src_img)

# clip dst_img with src_img, where src_img.pixel is not alpha
# like blend_rect, but clip instead of blend
# can use clip clr to change color of clipped region
static func clip_image(dst_img, src_img, rect, pos, _clip_clr=''):
    var dst_size = dst_img.get_size()
    var src_size = src_img.get_size()
    var clip_clr = Color(0,0,0,0) if _clip_clr == '' else Color(_clip_clr)
    for i in rect.size.x:
        var _x = i + rect.position.x
        var _sx = i + pos.x
        if _x > src_size.x or _x < 0: continue
        if _sx > dst_size.x or _sx < 0: continue
        for j in rect.size.y:
            var _y = j + rect.position.y
            var _sy = j + pos.y
            if _y > src_size.y or _y < 0: continue
            if _sy > dst_size.y or _sy < 0: continue
            var clr = src_img.get_pixel(_x, _y)
            if clr.a != 0: dst_img.set_pixel(_sx, _sy, clip_clr)

static func clip_image_mask(dst_img, src_img, rect, pos, _clip_clr=''):
    # this is 3-times faster
    var dst_size = dst_img.get_size()
    var src_size = src_img.get_size()
    var empty_img = Image.create_empty(dst_size.x, dst_size.y, false,Image.FORMAT_RGBA8)
    var msk_img = Image.create_empty(dst_size.x, dst_size.y, false, Image.FORMAT_RGBA8)
    msk_img.blit_rect(src_img, rect, pos)
    dst_img.blit_rect_mask(empty_img, msk_img, Rect2i(0,0,src_size.x,src_size.y), Vector2i.ZERO)


# -------------------------------------------------
static func create(icon):
    return set_sprite(Sprite2D.new(), icon)
# -------------------------------------------------
static func set_sprite_size(sprite:Node, frame_size, region_offset=Vector2i.ZERO):
    var tex_size = sprite.texture.get_size()
    if frame_size is Array: frame_size = Vector2i(frame_size[0], frame_size[1])
    if region_offset is Array: region_offset = Vector2i(region_offset[0], region_offset[1])
    sprite.hframes = int(tex_size.x / frame_size.x)
    sprite.vframes = int(tex_size.y / frame_size.y)
    if region_offset:
        sprite.region_enabled = true
        if int(tex_size.x) % int(frame_size.x) != 0 or int(tex_size.y) % int(frame_size.y) != 0:
            sprite.region_rect = Rect2(region_offset.x, region_offset.y, frame_size.x*sprite.hframes, frame_size.y*sprite.vframes)
        else:
            sprite.region_rect = Rect2(region_offset.x, region_offset.y, tex_size.x, tex_size.y)
    else:
        if int(tex_size.x) % int(frame_size.x) != 0 or int(tex_size.y) % int(frame_size.y) != 0:
            sprite.region_enabled = true
            sprite.region_rect = Rect2(0,0,frame_size.x*sprite.hframes, frame_size.y*sprite.vframes)
        else:
            sprite.region_enabled = false

static func set_sprite_coords(sprite:Node, coords):
    if coords is Array:
        sprite.frame_coords = Vector2(coords[0], coords[1])
    elif coords is Vector2 or coords is Vector2i:
        sprite.frame_coords = coords
    else:
        printerr('frame_coords must be array or vector2')

# static func set_sprite_region(sprite:Node, reg_pos, frame_size):
#     var tex_size = sprite.texture.get_size()
#     var frame_size_x
#     var frame_size_y
#     if frame_size is Array:
#         frame_size_x = frame_size[0]
#         frame_size_y = frame_size[1]
#     else:
#         frame_size_x = frame_size.x
#         frame_size_y = frame_size.y
#     var reg_pos_x
#     var reg_pos_y
#     if reg_pos is Array:
#         reg_pos_x = reg_pos[0]
#         reg_pos_y = reg_pos[1]
#     else:
#         reg_pos_x = reg_pos.x
#         reg_pos_y = reg_pos.y

#     sprite.region_enabled = true
#     sprite.region_rect = Rect2(reg_pos_x,reg_pos_y,frame_size_x, frame_size_y)
#     sprite.frame = 0

static func set_sprite_texture(sprite:Node, texture):
    var tex = Util.get_texture(texture)
    if tex: sprite.texture = tex

## 设置精灵的属性
## [param spr] 目标精灵
## [param params] 参数字典或配置路径
## [param skip_pos] 是否跳过位置相关设置
## [return] 设置后的精灵
static func set_sprite(spr: Sprite2D, params = {}, skip_pos := false) -> Sprite2D:
    # 处理字符串参数
    if params is String:
        params = Raw.load(params)
    
    # 参数验证
    if params == null:
        printerr('set_sprite: Nil sprite params', spr)
        return spr
    
    # 设置纹理
    var params_texture = params.get('texture')
    set_sprite_texture(spr, params_texture)
    if not spr.texture:
        printerr('set_sprite: Invalid texture', params_texture)
        return spr
    
    # 设置帧大小和区域
    var params_frame_size = params.get('frame_size', spr.texture.get_size())
    var params_region_offset = params.get('region_offset', Vector2i.ZERO)
    set_sprite_size(spr, params_frame_size, params_region_offset)
    
    # 设置帧坐标
    var params_frame_coords = Vector2i.ZERO
    if params.has('frame_coords'):
        params_frame_coords = params.frame_coords
    elif params.has('rnd_frame_coords'):
        params_frame_coords = Rnd.pick(params.rnd_frame_coords)
    set_sprite_coords(spr, params_frame_coords)
    
    # 如果不跳过位置设置
    if not skip_pos:
        _set_sprite_transform(spr, params)
    
    return spr

## 设置精灵的变换属性
static func _set_sprite_transform(spr: Sprite2D, params: Dictionary) -> void:
    # 居中属性
    if params.has('centered'):
        spr.centered = params.centered
    
    # 位置
    if params.has('position'):
        spr.position = params.position
    
    # 缩放
    if params.has('scale'):
        var scale = params.scale
        match typeof(scale):
            TYPE_VECTOR2, TYPE_VECTOR2I:
                spr.scale = scale
            TYPE_ARRAY:
                spr.scale = Vector2(scale[0], scale[1])
            TYPE_FLOAT, TYPE_INT:
                spr.scale = Vector2.ONE * scale
            _:
                printerr('invalid scale type in params:', scale)
    
    # 偏移
    if params.has('offset'):
        spr.offset = params.offset
    
    # Z轴偏移
    if params.has('offset_z'):
        spr.position.y += params.offset_z
        spr.offset.y -= params.offset_z
    
    # Z索引
    if params.has('z_index'):
        spr.z_index = params.z_index

# same as set_sprite, but set TextureRect
# can reuse the sprite_raw config
static func set_tex_rect(rec:TextureRect, params={}):
    if params is String: 
        params = Raw.load(params)

    if params == null: 
        printerr('set_sprite: Nil sprite params', rec)
        return

    if params.has('frame_size'):
        rec.texture = get_atlas(params)  # tex rect has no frame size
    else:
        var params_texture = params.get('texture')
        set_sprite_texture(rec, params_texture)

    if params.has('scale'): 
        var tex_size = rec.texture.get_size()
        if params.scale is Vector2 or params.scale is Vector2i:
            rec.custom_minimum_size = Vector2(tex_size.x * params.scale.x, tex_size.y * params.scale.y)
        elif params.scale is Array:
            rec.custom_minimum_size = Vector2(tex_size.x * params.scale[0], tex_size.y * params.scale[1])
        elif params.scale is float or params.scale is int:
            rec.custom_minimum_size = tex_size * params.scale
        else:
            printerr('invalid scale type in params:', params.scale)
    if params.has('expand'): rec.expand_mode = params.expand
    if params.has('stretch'): rec.stretch_mode = params.stretch
    if params.has('z_index'): rec.z_index = params.z_index

# --------------------------
static func set_clip_bottom(spr:Sprite2D, baseline=0):
    # baseline is count from bottom to up
    var rect = get_coord_rect(spr)
    var n_rect
    if rect.size.y <= baseline:
     n_rect = Rect2i(rect.position.x, rect.position.y, rect.size.x, 0)
    else:
     n_rect = Rect2i(rect.position.x, rect.position.y, rect.size.x, rect.size.y - baseline)
    
    spr.frame = 0
    spr.hframes = 1
    spr.vframes = 1
    spr.region_enabled = true
    spr.region_rect = n_rect

static func set_clip_top(spr:Sprite2D, clip_top=0):
    # baseline is count from bottom to up
    var rect = get_coord_rect(spr)
    var n_rect
    n_rect = Rect2i(rect.position.x, rect.position.y + clip_top, rect.size.x, rect.size.y - clip_top)
    spr.offset.y +=clip_top
    
    spr.frame = 0
    spr.hframes = 1
    spr.vframes = 1
    spr.region_enabled = true
    spr.region_rect = n_rect

static func reset_sprite(spr):
    spr.region_enabled = false
    spr.hframes=1
    spr.vframes=1
    spr.frame = 0
    spr.flip_h = false
    spr.flip_v = false
    spr.offset = Vector2.ZERO
    spr.centered = true


static func get_sprite_coord_img(sprite) -> Image:
    var rect = get_coord_rect(sprite)
    var img = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
    var src_img = sprite.texture.get_image()
    img.blit_rect(src_img, rect, Vector2i.ZERO)
    return img

static func get_sprite_coord_tex(sprite) -> ImageTexture:
    return ImageTexture.create_from_image(get_sprite_coord_img(sprite))

static func get_atlas(icon):
    var atl = AtlasTexture.new()
    if icon is String: icon = Raw.load(icon)
    atl.atlas = Util.get_texture(icon.texture)
    if icon.frame_coords is Array:
        icon.frame_coords = Vector2(icon.frame_coords[0], icon.frame_coords[1])
    if icon.frame_size is Array:
        icon.frame_size = Vector2(icon.frame_size[0], icon.frame_size[1])
    var pos = Vector2(icon.frame_coords.x * icon.frame_size.x, icon.frame_coords.y * icon.frame_size.y)
    var size = Vector2(icon.frame_size.x, icon.frame_size.y)
    atl.region = Rect2(pos, size)
    return atl

static func get_sprites_combined(sprites_dic, size:Vector2i, offset:Vector2=Vector2.ZERO) -> ImageTexture:
    var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
    for spr_pair in sprites_dic:
        var spr = spr_pair.spr
        if spr == null or !is_instance_valid((spr)): continue
        var pos = spr_pair.pos as Vector2
        var rect = get_coord_rect(spr)
        var src_img = spr.texture.get_image()
        img.blit_rect(src_img, rect, pos+offset)
    return ImageTexture.create_from_image(img)

static func get_sprites_combined_img(sprites_dic, size:Vector2i, offset:Vector2=Vector2.ZERO) -> Image:
    var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
    for spr_pair in sprites_dic:
        var spr = spr_pair.spr
        if spr == null or !is_instance_valid((spr)): continue
        var pos = spr_pair.pos as Vector2
        var rect = get_coord_rect(spr)
        var src_img = spr.texture.get_image()
        img.blit_rect(src_img, rect, pos+offset)
    return img

static func get_tex_combined(src_img, rect_dic, size:Vector2i, offset:Vector2=Vector2.ZERO) -> ImageTexture:
    var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
    for r_pair in rect_dic:
        var rect = r_pair.rect
        var pos = r_pair.pos as Vector2
        img.blit_rect(src_img, rect, pos+offset)
    return ImageTexture.create_from_image(img)

static func create_spr_outline(spr:Sprite2D, clr='FFFFFF'):
    var spr2 = Sprite2D.new()
    spr.add_child(spr2)
    var src_img = get_sprite_coord_img(spr)
    var size = src_img.get_size()
    var new_img = Image.create(size.x+2, size.y+2, false, Image.FORMAT_RGBA8)
    new_img.blit_rect(src_img, Rect2(0,0,size.x, size.y), Vector2(1, 1))
    var new_tex = ImageTexture.create_from_image(new_img)

    spr2.texture = new_tex
    # spr2.frame_coords=Vector2(0,0)
    # spr2.hframes=1
    # spr2.vframes=1
    # spr2.region_enabled = false
    # spr2.scale = Vector2(1, 1)
    spr2.position = Vector2(-1, -1)
    spr2.show_behind_parent = true
    spr2.centered = spr.centered
    Util.shade(spr2, 'outline_hint', {outline_color=Color(clr)})
    # var spr3 = spr2.duplicate()
    # spr.add_child(spr3)
    # spr3.position = Vector2(0, 1)
    # var spr4 = spr2.duplicate()
    # spr.add_child(spr4)
    # spr4.position = Vector2(-1, 0)
    # var spr5 = spr2.duplicate()
    # spr.add_child(spr5)
    # spr5.position = Vector2(0, -1)


# -------------------------------------------------------
