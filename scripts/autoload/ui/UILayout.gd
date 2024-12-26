class_name UILayout

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

static func set_layout(node, preset, offset=Vector2.ZERO):
    if not 'anchors_preset' in node: return
    node.set_anchors_preset(preset)
    node.set_offsets_preset(preset, 3)
    
    if offset:
        match preset:
            PRESET_BOTTOM_RIGHT, PRESET_BOTTOM_LEFT, PRESET_BOTTOM_WIDE, PRESET_CENTER_BOTTOM, PRESET_BOTTOM_CENTER:
                offset.y = -offset.y
        match preset:
            PRESET_BOTTOM_RIGHT, PRESET_TOP_RIGHT, PRESET_RIGHT_WIDE,PRESET_CENTER_RIGHT:
                offset.x = -offset.x

        node.offset_top += offset.y
        node.offset_bottom += offset.y
        node.offset_right += offset.x
        node.offset_left += offset.x
        
    node.grow_horizontal = GROW_DIRECTION_END
    node.grow_vertical = GROW_DIRECTION_END
    
    match preset:
        PRESET_TOP_RIGHT:
            node.grow_horizontal = GROW_DIRECTION_BEGIN
        PRESET_BOTTOM_LEFT:
            node.grow_vertical = GROW_DIRECTION_BEGIN
        PRESET_BOTTOM_RIGHT:
            node.grow_horizontal = GROW_DIRECTION_BEGIN
            node.grow_vertical = GROW_DIRECTION_BEGIN
        PRESET_CENTER_LEFT:
            node.grow_vertical = GROW_DIRECTION_BOTH
        PRESET_CENTER_TOP:
            node.grow_horizontal = GROW_DIRECTION_BOTH
        PRESET_CENTER_RIGHT:
            node.grow_vertical = GROW_DIRECTION_BOTH
            node.grow_horizontal = GROW_DIRECTION_BEGIN
        PRESET_CENTER_BOTTOM:
            node.grow_vertical = GROW_DIRECTION_BEGIN
            node.grow_horizontal = GROW_DIRECTION_BOTH
        PRESET_CENTER:
            node.grow_horizontal = GROW_DIRECTION_BOTH
            node.grow_vertical = GROW_DIRECTION_BOTH
        PRESET_RIGHT_WIDE:
            node.grow_horizontal = GROW_DIRECTION_BEGIN
        PRESET_BOTTOM_WIDE:
            node.grow_vertical = GROW_DIRECTION_BEGIN
        PRESET_VCENTER_WIDE:
            node.grow_horizontal = GROW_DIRECTION_BOTH
        PRESET_HCENTER_WIDE:
            node.grow_vertical = GROW_DIRECTION_BOTH 
