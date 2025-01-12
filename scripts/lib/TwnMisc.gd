class_name TwnMisc

var shake_power = 3  # Trauma exponent. Use [2, 3].
var shake_offset = Vector2(20, 10)  # Maximum hor/ver shake in pixels.
var shake_roll = 0.0  # Maximum rotation in radians (use sparingly).
var _shake_fix = Vector2.ZERO
var target

func _init(_tar):
    target = _tar

static func of(_tar):
    var id = '_twn_misc'
    if _tar.has_meta(id):
        return _tar.get_meta(id)
    else:
        var tm = TwnMisc.new(_tar)
        _tar.set_meta(id, tm)
        return tm

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


func _follow_number(val, _tpl=''):
    if !is_valid(target): return
    if _tpl:
        target.text = _tpl % val
    else:
        target.text = str(int(val))

func _follow_time(val, _tpl=''):
    if !is_valid(target): return
    var t = sec_to_hhmm(val)
    if _tpl:
        target.text = _tpl % t
    else:
        target.text = t

func hhmm_to_sec(hhmm: String) -> float:
    var split = Array(hhmm.replace(",", ".").split_floats(":"))
    if split.size() == 3:
        return split[0] * 60 * 60 + split[1] * 60 + split[2]
    else:
        return split[0] * 60 + split[1]

func sec_to_hhmm(sec):
    if sec > 3600:
        var tl = fmod(sec, 3600)
        return  '%02d:%02d:%02d' % [int(sec) / 3600, int(tl) / 60.0, int(fmod(tl, 60))]
    else:
        return  '%02d:%02d' % [int(sec) / 60.0, int(fmod(sec, 60))]
