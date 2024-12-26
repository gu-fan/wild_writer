class_name TwnMisc

var shake_power = 3  # Trauma exponent. Use [2, 3].
var shake_offset = Vector2(20, 10)  # Maximum hor/ver shake in pixels.
var shake_roll = 0.0  # Maximum rotation in radians (use sparingly).
var _shake_fix = Vector2.ZERO
var target

func is_valid(nd): 
    return Util.is_valid(nd)

func _follow_shake(val):
    if is_valid(target):
        var amount = pow(1.0 - val, shake_power)
        if shake_roll: target.rotation = shake_roll * amount * randf_range(-1, 1)
        var shake_off_x = _shake_fix.x + shake_offset.x * amount * randf_range(-1, 1)
        var shake_off_y = _shake_fix.y + shake_offset.y * amount * randf_range(-1, 1)


        if 'offset' in target:
            target.offset.x = shake_off_x
            target.offset.y = shake_off_y
            if val == 1.0:
                target.offset = Vector2.ZERO
        else:
            var _orig = Util._get_orig(target, 'position')

            target.position.x = _orig.x + shake_off_x
            target.position.y = _orig.y + shake_off_y

            if val == 1.0:
                target.position = _orig
