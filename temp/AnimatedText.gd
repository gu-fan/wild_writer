extends Node2D
class_name AnimatedText

signal text_appeared
signal text_cleared

class CharNode extends Node2D:
    var shaped_text_rid: RID
    var baseline: float
    var appear_time: float
    var clear_time: float = -1.0
    var text_server: TextServer
    var size: Vector2
    var enable_rect := false
    var fonts: Array
    var font_size := 32
    
    func _init(ts: TextServer, rid: RID, b: float, t: float, s: Vector2, f:Array, fs:int):
        shaped_text_rid = rid
        baseline = b
        appear_time = t
        text_server = ts
        size = s
        fonts = f
        font_size = fs
    
    func _draw():
        if !text_server.shaped_text_is_ready(shaped_text_rid):
            return
            
        # var draw_pos = Vector2(-size.x/2, baseline)
        var draw_pos = Vector2(-size.x/2, 0)
        
        text_server.shaped_text_draw_outline(
            shaped_text_rid,
            get_canvas_item(),
            draw_pos,
            -1, -1,
            2,
            Color(0, 0, 0, modulate.a)
        )
        text_server.shaped_text_draw(
            shaped_text_rid,
            get_canvas_item(),
            draw_pos,
            -1, -1,
            modulate
        )
        if enable_rect:
            var glyphs = text_server.shaped_text_get_glyphs(shaped_text_rid)
            var offset = text_server.font_get_glyph_offset(fonts[0], Vector2(font_size,0), glyphs[0].index)
            var size = text_server.font_get_glyph_size(fonts[0], Vector2(font_size, 0), glyphs[0].index)
            var rect = Rect2(draw_pos+ offset, size)
            draw_rect(rect, Color.GREEN, false)

var text_server: TextServer
var font: Font
var fonts: Array
var font_size := 32

# 动画参数
var time: float = 0.0
var wave_speed: float = 3.0
var wave_height: float = 10.0
var char_delay: float = 0.1
var is_clearing := false
var clear_duration := 0.3
var enable_wave := true  # 添加波浪效果开关
var enable_rect := true  # 添加波浪效果开关

func _ready() -> void:
    text_server = TextServerManager.get_primary_interface()
    font = load("res://assets/fonts/NotoSans/NotoSansSC-Regular.ttf")
    fonts = font.get_rids()

func set_text(new_text: String) -> void:
    clear_text()
    _create_text(new_text)

func _create_text(text: String) -> void:
    var current_x = 0.0
    for i in text.length():
        var char = text[i]
        
        var shaped_text_rid = text_server.create_shaped_text()
        text_server.shaped_text_add_string(shaped_text_rid, char, fonts, font_size)
        text_server.shaped_text_shape(shaped_text_rid)
        
        var size = text_server.shaped_text_get_size(shaped_text_rid)
        var baseline = text_server.shaped_text_get_ascent(shaped_text_rid)
        
        var char_node = CharNode.new(text_server, shaped_text_rid, baseline, time + char_delay * i, size, fonts, font_size)
        char_node.position.x = current_x + size.x/2
        char_node.position.y = baseline / 2
        char_node.modulate.a = 0.0
        add_child(char_node)
        
        current_x += size.x

func clear_text() -> void:
    is_clearing = true
    for child in get_children():
        if child is CharNode and child.clear_time < 0:
            child.clear_time = time

func _process(delta: float) -> void:
    time += delta
    
    var all_appeared = true
    for child in get_children():
        if not (child is CharNode):
            continue
            
        var char_node: CharNode = child
        var char_time = time - char_node.appear_time
        
        if char_time < 0:
            char_node.modulate.a = 0.0
            char_node.scale = Vector2.ZERO
            all_appeared = false
            continue
            
        if char_node.clear_time >= 0:
            # 消失动画
            var clear_time = time - char_node.clear_time
            char_node.modulate.a = 1.0 - (clear_time / clear_duration)
            char_node.scale = Vector2.ONE * (1.0 + clear_time * 2)
            char_node.position.y = -clear_time * 50
            
            if clear_time >= clear_duration:
                if char_node.shaped_text_rid.is_valid():
                    text_server.free_rid(char_node.shaped_text_rid)
                char_node.queue_free()
        else:
            # 出现动画
            # 只在启用波浪效果时应用
            char_node.position.y = int(enable_wave) * sin(char_time * wave_speed) * wave_height
            char_node.modulate.a = min(char_time / 0.3, 1.0)
            
            # 弹跳缩放效果
            var bounce_duration := 0.4
            if char_time < bounce_duration:
                var t = char_time / bounce_duration
                char_node.scale = Vector2.ONE * (1.0 + sin(t * PI) * 0.3)
            else:
                char_node.scale = Vector2.ONE
            
            if char_time < 0.3:
                all_appeared = false
            
        char_node.queue_redraw()

        char_node.enable_rect = enable_rect
    
    if all_appeared and not is_clearing:
        emit_signal("text_appeared")
        
    if is_clearing and get_child_count() == 0:
        is_clearing = false
        emit_signal("text_cleared")

func _exit_tree() -> void:
    for child in get_children():
        if child is CharNode:
            if child.shaped_text_rid.is_valid():
                text_server.free_rid(child.shaped_text_rid)
