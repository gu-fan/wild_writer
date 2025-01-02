extends Node2D
class_name AnimatedText

signal text_appeared
signal text_cleared

class CharNode extends Node2D:
    var shaped_text_rid: RID
    var baseline: float
    var appear_time: float
    var char_delay: float
    var clear_time: float = -1.0
    var text_server: TextServer
    var size: Vector2
    var character: String  # 添加字符属性用于比较
    var enable_rect := false
    var fonts: Array
    var font_size := 32 
    var offset :=Vector2.ZERO
    var base_position := Vector2.ZERO
    var base_offset := Vector2.ZERO
    var index := 0

    var shake_intensity:float  = 3.0
    var shake_pos := Vector2.ZERO
    var enable_shake := false

    # 彩虹效果
    var enable_rainbow := false
    var rainbow_speed := 1.0
    var rainbow_offset := 0.0  # 用于位置偏移
    var rainbow_saturation := 0.8
    var rainbow_value := 1.0
    var text_color := Color.WHITE
    
    # 动画状态
    enum State { WAITING, APPEARING, IDLE, DISAPPEARING,FINISH }
    var current_state := State.WAITING
    
    # 动画参数
    var appear_duration := 0.15
    var clear_duration := 0.15
    var bounce_scale := 0.5
    var appear_offset := 50.0
    var disappear_offset := 80.0
    var disappear_scale := 0.5
    
    # 动画时间追踪
    var anim_time := 0.0
    
    signal disappeared  # 添加消失信号
    
    func _init(ts: TextServer, rid: RID, b: float, t: float, s: Vector2, c: String, f:Array, fs:int, cd: float, of: Vector2 = Vector2.ZERO):
        shaped_text_rid = rid
        baseline = b
        appear_time = t
        text_server = ts
        size = s
        character = c
        fonts = f
        font_size = fs
        char_delay = cd
        offset = of

    func _process(delta: float):
        anim_time += delta
        
        # 处理抖动
        if enable_shake:
            shake_pos = Vector2(
                randf_range(-shake_intensity, shake_intensity),
                randf_range(-shake_intensity, shake_intensity)
            )
        else:
            shake_pos = Vector2.ZERO
            
        # 处理彩虹效果
        if enable_rainbow:
            var time = Time.get_ticks_msec() / 1000.0
            var hue = fmod(time * rainbow_speed + rainbow_offset, 1.0)
            text_color = Color.from_hsv(hue, rainbow_saturation, rainbow_value)

        
        match current_state:
            State.WAITING:
                modulate.a = 0.0
                scale = Vector2.ZERO
                
            State.APPEARING:
                var t = anim_time / appear_duration
                if t >= 1.0:
                    current_state = State.IDLE
                    modulate.a = 1.0
                    scale = Vector2.ONE
                    position.y = base_position.y
                else:
                    modulate.a = t
                    scale = Vector2.ONE * (1.0 + sin(t * PI) * bounce_scale)
                    position.y = base_position.y + appear_offset * (1.0 - t)

                queue_redraw()
            
            State.IDLE:
                pass
                
            State.FINISH:
                var t = anim_time / clear_duration
                if t >= 1.0:
                    if shaped_text_rid.is_valid():
                        text_server.free_rid(shaped_text_rid)
                    emit_signal("disappeared")
                    queue_free()
                else:
                    modulate.a = 1.0 - t
                    scale = Vector2.ONE * (1.0 + t * disappear_scale)
                    # position.y = base_position.y - t * disappear_offset
                    queue_redraw()

            State.DISAPPEARING:
                var t = anim_time / clear_duration
                if t >= 1.0:
                    if shaped_text_rid.is_valid():
                        text_server.free_rid(shaped_text_rid)
                    emit_signal("disappeared")
                    queue_free()
                else:
                    modulate.a = 1.0 - t
                    scale = Vector2.ONE * (1.0 + t * disappear_scale)
                    position.y = base_position.y - t * disappear_offset
                    queue_redraw()
        
    
    func appear() -> void:
        current_state = State.APPEARING
        anim_time = 0.0
    
    func disappear() -> void:
        if current_state != State.DISAPPEARING:
            current_state = State.DISAPPEARING
            anim_time = 0.0
    func finish() -> void:
        if current_state != State.FINISH:
            current_state = State.FINISH
            anim_time = 0.0

    func _draw():
        if !shaped_text_rid.is_valid():
            return
        # if !text_server.shaped_text_is_ready(shaped_text_rid):
        #     return
            
        # var draw_pos = Vector2(-size.x/2, baseline)
        var orig_pos = Vector2(-size.x/2, 0) + offset
        var draw_pos = orig_pos + shake_pos

        if current_state == State.FINISH:
            var glyphs = text_server.shaped_text_get_glyphs(shaped_text_rid)
            if glyphs.size():
                var g_offset = text_server.font_get_glyph_offset(fonts[0], Vector2(font_size,0), glyphs[0].index)
                var g_size = text_server.font_get_glyph_size(fonts[0], Vector2(font_size, 0), glyphs[0].index)
                var rect = Rect2(orig_pos+ g_offset, g_size)
                draw_rect(rect, Color.WHITE, true)
            # var rect = Rect2(draw_pos+ Vector2(-size.x/2, -size.y/2), size)
            # draw_rect(rect, Color.WHITE, true)
#             text_server.shaped_text_draw(
#                 shaped_text_rid,
#                 get_canvas_item(),
#                 draw_pos,
#                 -1, -1,
#                 # Color('2ce8f5'),
#             )
        else:
            var oc = Color('2ce8f5')
            var nc =Color.from_hsv(oc.h + Rnd.rangef(-0.06, 0.06), oc.s, oc.v+0.1, modulate.a)
            text_server.shaped_text_draw(
                shaped_text_rid,
                get_canvas_item(),
                draw_pos + Vector2(2 , 2),
                -1, -1,
                nc
            )
            # text_server.shaped_text_draw(
            #     shaped_text_rid,
            #     get_canvas_item(),
            #     draw_pos,
            #     -1, -1,
            #     text_color * modulate  # 将彩虹颜色与透明度结合
            # )
        if enable_rect:
            var glyphs = text_server.shaped_text_get_glyphs(shaped_text_rid)
            if glyphs.size():
                var g_offset = text_server.font_get_glyph_offset(fonts[0], Vector2(font_size,0), glyphs[0].index)
                var g_size = text_server.font_get_glyph_size(fonts[0], Vector2(font_size, 0), glyphs[0].index)
                var rect = Rect2(orig_pos+ g_offset, g_size)
                draw_rect(rect, Color.GREEN, false)
    # func _exit_tree():
    #     if shaped_text_rid.is_valid():
    #         text_server.free_rid(shaped_text_rid)

var text_server: TextServer
var font: Font
var fonts: Array
var font_size := 64

# 动画参数
var time: float = 0.0
var wave_speed: float = 6.0
var wave_height: float = 4.0
var char_delay: float = 0.01
var is_clearing := false
var appear_duration := 0.12
var clear_duration := 0.15
var enable_wave := true
var enable_rect := false
var enable_shake := false

# 在主节点中添加彩虹控制
var enable_rainbow := false
var rainbow_speed := 1.0
var rainbow_phase := 0.2  # 字符间的色相偏移

var is_finish_compose = false

var centered := true :
    set(v):
        centered = v
        _update_position()

func _update_position():
    if not centered: return
    var rect = get_rect()
    offset = -rect.size / 2

var offset := Vector2.ZERO :
    set(v):
        offset = v
        for child in get_children():
            if not (child is CharNode): continue
            var char_node: CharNode = child
            char_node.base_offset = offset


var text := '' : 
    set(v):
        set_text(v)
        text = v

func _ready() -> void:
    text_server = TextServerManager.get_primary_interface()
    # font = load("res://assets/fonts/NotoSans/NotoSansSC-Regular.ttf")
    font = load("res://effects/font.tres")
    fonts = font.get_rids()

func set_text(new_text: String) -> void:
    var old_chars = {}
    var char_positions = {}
    var total_index := 0
    
    # 保存现有字符节点的信息
    for child in get_children():
        if child is CharNode:
            if child.shaped_text_rid.is_valid():
                old_chars[child.get_instance_id()] = child
                char_positions[child.base_position.x] = child
                total_index = max(total_index, child.appear_time / char_delay)
    
    var current_x = 0.0
    var new_chars = {}
    
    # 创建新的字符节点
    for i in new_text.length():
        var char = new_text[i]
        var shaped_text_rid = text_server.create_shaped_text()
        text_server.shaped_text_add_string(shaped_text_rid, char, fonts, font_size)
        text_server.shaped_text_shape(shaped_text_rid)
        
        var size = text_server.shaped_text_get_size(shaped_text_rid)
        var baseline = text_server.shaped_text_get_ascent(shaped_text_rid)
        var target_x = current_x + size.x/2
        
        var char_node: CharNode
        
        # 检查是否有字符节点在相同位置且是相同字符
        if target_x in char_positions:
            var existing_node = char_positions[target_x]
            if existing_node.character == char:
                char_node = existing_node
                old_chars.erase(existing_node.get_instance_id())
        
        # 如果需要创建新节点
        if not char_node:
            char_node = CharNode.new(text_server, shaped_text_rid, baseline, time + char_delay * i, size, char, fonts, font_size, char_delay * i)
            char_node.position = Vector2(target_x, baseline)
            char_node.base_position = Vector2(target_x, baseline)
            char_node.modulate.a = 0.0
            char_node.enable_rect = enable_rect
            char_node.index = i
            
            # 设置彩虹效果
            char_node.enable_rainbow = enable_rainbow
            char_node.rainbow_speed = rainbow_speed
            char_node.rainbow_offset = rainbow_phase * i  # 每个字符一个偏移
            
            add_child(char_node)
            char_node.disappeared.connect(queue_redraw)
        
        new_chars[char_node.get_instance_id()] = true
        current_x += size.x
    
    # 清除未使用的旧字符
    for char_node in old_chars.values():
        if is_finish_compose:
            char_node.finish()
        else:
            char_node.disappear()

    if enable_rect: queue_redraw()

    if centered: _update_position()

    is_finish_compose = false

func _process(delta: float) -> void:
    time += delta
    
    var all_appeared = true
    for child in get_children():
        if not (child is CharNode):
            continue
            
        var char_node: CharNode = child
        if !char_node.shaped_text_rid.is_valid():
            continue
            
        # 检查是否到达出现时间
        if time >= char_node.appear_time and char_node.current_state == CharNode.State.WAITING:
            char_node.appear()
        
        char_node.position.x = char_node.base_position.x + char_node.base_offset.x
        # 波浪效果
        if enable_wave and char_node.current_state == CharNode.State.IDLE:
            var wave_time = time - char_node.appear_time
            char_node.position.y = char_node.base_position.y + sin(wave_time * wave_speed) * wave_height
        
        if char_node.current_state != CharNode.State.IDLE:
            all_appeared = false

    # if all_appeared and not is_clearing:
    #     emit_signal("text_appeared")
    if enable_rect: queue_redraw()

func _draw():
    if enable_rect:
        var rect = get_rect()
        draw_rect(Rect2(rect.position.x + offset.x, rect.position.y, rect.size.x, rect.size.y), Color.YELLOW, false)

# 获取当前文本的边界矩形
func get_rect() -> Rect2:
    if get_child_count() == 0:
        return Rect2()
        
    var min_x := INF
    var max_x := -INF
    var min_y := INF
    var max_y := -INF
    
    for child in get_children():
        if not (child is CharNode):
            continue
            
        var char_node: CharNode = child
        if !char_node.shaped_text_rid.is_valid():
            continue
            
        # 获取字符的基础位置
        var pos = char_node.base_position
        var half_width = char_node.size.x/2
        
        # 计算字符的边界
        min_x = min(min_x, pos.x - half_width)
        max_x = max(max_x, pos.x + half_width)
        
        # 考虑字符的完整高度（包括基线和下行高度）
        var ascent = char_node.baseline
        var descent = char_node.size.y - char_node.baseline
        min_y = min(min_y, pos.y - ascent)
        max_y = max(max_y, pos.y + descent)
    
    # 如果没有有效的字符，返回空矩形
    if min_x == INF:
        return Rect2()
    
    # 返回计算出的边界矩形
    return Rect2(
        Vector2(min_x, min_y),
        Vector2(max_x - min_x, max_y - min_y)
    )

func finish_compose():
    is_finish_compose = true
