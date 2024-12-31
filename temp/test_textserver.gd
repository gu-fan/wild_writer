extends Node2D

var text_server: TextServer
var font: Font
var char_data: Array[CharData] = []
var base_pos := Vector2(100, 100)

# Animation parameters
var time: float = 0.0
var wave_speed: float = 3.0
var wave_height: float = 10.0
var char_delay: float = 0.1  # Delay between characters

class CharData:
    var shaped_text_rid: RID
    var pos: Vector2
    var size: Vector2
    var baseline: float
    var appear_time: float
    
    func _init(rid: RID, p: Vector2, s: Vector2, b: float, t: float):
        shaped_text_rid = rid
        pos = p
        size = s
        baseline = b
        appear_time = t

func _ready():
    # Get the primary text server interface
    text_server = TextServerManager.get_primary_interface()
    
    font = load("res://assets/fonts/NotoSans/NotoSansSC-Regular.ttf")
    # Create a font resource
    
    # Set up text
    var test_text = "Hello World! 👋"
    var fonts = font.get_rids()
    var font_size = 32
    
    # Process each character
    var current_x = 0.0
    for i in test_text.length():
        var char = test_text[i]
        
        # Create shaped text for this character
        var shaped_text_rid = text_server.create_shaped_text()
        text_server.shaped_text_add_string(shaped_text_rid, char, fonts, font_size)
        text_server.shaped_text_shape(shaped_text_rid)
        
        # Get metrics for this character
        var size = text_server.shaped_text_get_size(shaped_text_rid)
        var baseline = text_server.shaped_text_get_ascent(shaped_text_rid)
        
        # Store character data
        char_data.append(CharData.new(
            shaped_text_rid,
            Vector2(current_x, 0),  # Local position (will be offset by base_pos)
            size,
            baseline,
            char_delay * i  # Each character appears with a delay
        ))
        
        # Update position for next character
        current_x += size.x

func _process(delta):
    time += delta
    queue_redraw()

func _draw():
    for i in char_data.size():
        var data = char_data[i]
        if !text_server.shaped_text_is_ready(data.shaped_text_rid):
            continue
        
        # Calculate animation
        var char_time = time - data.appear_time
        if char_time < 0:
            continue
            
        # Wave animation
        var wave_offset = sin(char_time * wave_speed + i * 0.5) * wave_height
        
        # Fade in animation
        var alpha = min(char_time / 0.3, 1.0)
        
        # Scale animation
        var scale = min(char_time * 3, 1.0)
        scale = 1.0 + (scale - 1.0) * exp(-char_time * 5)
        
        # Calculate final position with baseline alignment
        var pos = base_pos + data.pos
        pos.y += data.baseline  # Align to baseline
        pos.y += wave_offset   # Add wave animation

        var size = text_server.shaped_text_get_size(data.shaped_text_rid)
        
        # # Draw the character
        text_server.shaped_text_draw_outline(
            data.shaped_text_rid,
            get_canvas_item(),
            pos,
            -1, -1,  # No clipping
            2,  # Outline size
            Color(0, 0, 0, alpha)  # Outline color
        )
        
        text_server.shaped_text_draw(
            data.shaped_text_rid,
            get_canvas_item(),
            pos,
            -1, -1,  # No clipping
            Color(1, 1, 1, alpha)  # Text color
        )
        var rect = Rect2(pos-Vector2(0, data.baseline), size)
        draw_rect(rect, Color.GREEN, false)

func _exit_tree():
    # Clean up resources
    for data in char_data:
        if data.shaped_text_rid.is_valid():
            text_server.free_rid(data.shaped_text_rid)
