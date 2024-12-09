class_name Rnd
# v3.1.0
# alternative with seeding: RndGenerator
# var rnd = RndGenerator.new('xxxx')
# ... same as this

static func seed(s):
    if s is String:
        seed(s.hash())
    else:
        seed(s)

# -----------------------
# 通用的随机ID生成函数
static func generate_random_id(parts: int, lengths: Array, n: int = 0) -> String:
    var id_parts = []
    for i in range(parts):
        var part = int(randf_range(0, 1) * 65536) & 0xFFFF
        id_parts.append(("%0" + str(lengths[i]) + "x") % part)
    
    var id_str = "".join(id_parts)
    if n:
        return ("%0" + str(lengths[0] - 1) + "x" % n).substr(0, lengths[0] - 1) + id_str
    return id_str

# 5位随机ID
static func mini_id(n: int = 0) -> String:
    return generate_random_id(2, [2, 3], n)

# 8位随机ID
static func id(n: int = 0) -> String:
    return generate_random_id(2, [4, 4], n)

# 11位随机ID
static func long_id(n: int = 0) -> String:
    return generate_random_id(3, [4, 4, 3], n)
# -----------------------
static func range(s, e=0):
    if e != 0:
        if e is float or s is float:
            return rangef(s, e)
        else:
            return rangei(s, e)
    else:
        if s is float:
            return rangef(s)
        else:
            return rangei(s)

## inclusive, no ending
static func rangei(s,e=0):
    if e:
        return randi_range(s, e-1)
    else:
        if s is Array:
            return randi_range(s[0], s[1]-1)
        elif s==0:
            return 0
        else:
            return randi_range(0, s-1)

static func rangef(s,e=0.0):
    if e:
        return randf_range(s, e)
    else:
        if s is Array:
            return randf_range(s[0], s[1])
        elif s==0:
            return 0
        else:
            return randf_range(0, s)
# -----------------------
static var _last_step = -9999
# return one rnd, and cache it
# the next generated should more than step
static func range_step(arr, step=10):
    var s = arr[0]
    var e = arr[1]
    var t = Rnd.range(s, e)
    while abs(t-_last_step) < step:
        t = Rnd.range(s, e)
    _last_step = t
    return t
# --------------------------------------------
static func some(arr, count=-1, _constrain_filter=null):
    if arr is String:
        arr = arr.split('')
    else:
        arr = arr.duplicate()
    var ret = []
    if _constrain_filter: arr = arr.filter(_constrain_filter)
    if arr.size():
        arr.shuffle()
        if count == -1:
            count = randi_range(1, arr.size())
        for i in count:
            if i >= arr.size(): break
            ret.append(arr[i])
        return ret
    return []

# --------------------
static func pick(arr, _constrain_filter=null):
    if arr is String:
        arr = arr.split('')
    if _constrain_filter: arr = arr.filter(_constrain_filter)
    if arr.size():
        return arr[randi_range(0, arr.size()-1)]
    return null

# --------------------
static func prior(dic):
    # from a priority dict {a: 0.3, b: 0.1, c:0.4}
    # return a or b by it's priority chance
    # => a:37.5% b:12.5% c: 50%
    var items = []
    var priorities = []
    var total = 0
    for k in dic:
        items.append(k)
        var next = total+dic[k]
        priorities.append([total, next])
        total = next

    var draw = randf_range(0, total)
    for i in priorities.size():
        var pri = priorities[i]
        if draw >= pri[0] and draw < pri[1]:
            return items[i]
    return null

static func get_or_pick(_c):
    if _c is Array:
        return Rnd.pick(_c)
    elif _c is Dictionary:
        return Rnd.prior(_c)
    else:
        return  _c
# ----------------------
static func is_true():
    # 50% chance
    return randi_range(0, 1) == 1

static func zero_or_one():
    return randi_range(0, 1)
    
static func chance(c=0.5):
    # chance(0.3) => 30% chance true
    # chance(0.9) => 90% chance true
    if c <= 0: return false
    if c >= 1: return true
    return Rnd.rangef(1 / float(c)) < 1
static func percent(c=50):
    # chance(30) => 30% chance true
    # chance(90) => 90% chance true
    if c <= 0: return false
    if c >= 100: return true
    return Rnd.rangef(100 / float(c)) < 1
# ------------------------------------
static func vector2(x0,x1,y0=null,y1=null) -> Vector2:
    if y0!=null and y1!=null:
        return Vector2(Rnd.range(x0, x1), Rnd.range(y0, y1))
    else:
        return Vector2(Rnd.range(x0, x1), Rnd.range(x0, x1))
static func vector2f(x0,x1,y0=null,y1=null) -> Vector2:
    if y0!=null and y1!=null:
        return Vector2(Rnd.rangef(x0, x1), Rnd.rangef(y0, y1))
    else:
        return Vector2(Rnd.rangef(x0, x1), Rnd.rangef(x0, x1))

static func vector2i(x0,x1,y0=null,y1=null) -> Vector2i:
    if y0!=null and y1!=null:
        return Vector2i(Rnd.rangei(x0, x1), Rnd.rangei(y0, y1))
    else:
        return Vector2i(Rnd.rangei(x0, x1), Rnd.rangei(x0, x1))
# ------------------------------------
# should use Rnd.some(Pos.range_spade(w,h))
# # return points within the radius of (w + h)
# # which shapes a spade. (vectori return a rectangle)
# static func vector2_in_spade(w,h) -> Vector2:
#     var a = Rnd.rangef(-w, w)
#     var b = Rnd.rangef(-h, h)
#     while (abs(a) + abs(b)) > (abs(w) + abs(h)):
#         a = Rnd.rangef(-w, w)
#         b = Rnd.rangef(-h, h)
#     return Vector2(a, b)

# static func vector2_in_circle(r) -> Vector2:
#     # TODO
#     return Vector2.ZERO
# static func vector2_in_ring(rmin, rmax) -> Vector2:
#     # TODO
#     return Vector2.ZERO
# ------------------------------------
static func vector3(x0,x1,z0=0,z1=0, y0=0, y1=0) -> Vector3:
    if y1:
        return Vector3(Rnd.range(x0, x1), Rnd.range(y0, y1), Rnd.range(z0, z1))
    elif z1:
        return Vector3(Rnd.range(x0, x1), y0, Rnd.range(z0, z1))
    else:
        return Vector3(Rnd.range(x0, x1), y0, z0)
static func vector3f(x0,x1,z0=0,z1=0, y0=0, y1=0) -> Vector3:
    if y1:
        return Vector3(Rnd.rangef(x0, x1), Rnd.rangef(y0, y1), Rnd.rangef(z0, z1))
    elif z1:
        return Vector3(Rnd.rangef(x0, x1), y0, Rnd.rangef(z0, z1))
    else:
        return Vector3(Rnd.rangef(x0, x1), y0, z0)
static func vector3i(x0,x1,z0=0,z1=0, y0=0, y1=0) -> Vector3i:
    if y1:
        return Vector3i(Rnd.rangei(x0, x1), Rnd.rangei(y0, y1), Rnd.rangei(z0, z1))
    elif z1:
        return Vector3i(Rnd.rangei(x0, x1), y0, Rnd.rangei(z0, z1))
    else:
        return Vector3i(Rnd.rangei(x0, x1), y0, z0)
# ------------------------------------
const DIR_VEC2I = [
    Vector2i(1,0), 
    Vector2i(0,1),
    Vector2i(-1,0),
    Vector2i(0,-1),
]
static func dir2i() -> Vector2i:
    return pick(DIR_VEC2I)
static func dir2f() -> Vector2:
    return Vector2(Rnd.rangef(-1, 1), Rnd.rangef(-1, 1)).normalized()
const DIR_VEC3I = [
        Vector3i(1,0,0), 
        Vector3i(0,1,0),
        Vector3i(0,0,1),
        Vector3i(-1,0,0),
        Vector3i(0,-1,0),
        Vector3i(0,0,-1),
    ]
static func dir3i() -> Vector3i:
    return pick(DIR_VEC3I)
static func dir3f() -> Vector3:
    return Vector3(Rnd.rangef(-1, 1), Rnd.rangef(-1, 1), Rnd.rangef(-1, 1)).normalized()
# ------------------------------------
static func color(with_alpha=false):
    if with_alpha:
        return Color(Rnd.rangef(1), Rnd.rangef(1), Rnd.rangef(1), Rnd.rangef(1))
    else:
        return Color(Rnd.rangef(1), Rnd.rangef(1), Rnd.rangef(1), 1)

static func hue(s=0.6,v=0.8):
    return Color.from_hsv(Rnd.rangef(1), s, v)
# ------------------------------------
# should use Rnd.pick(Pos.get_directions(4))
# static func direction(dir=4):
#     # return an direction based on dir, no Vector2.ZERO will be returned
#     if dir == 2:
#         return Rnd.pick([Vector2.LEFT, Vector2.RIGHT])
#     elif dir == 4:
#         return Rnd.pick([Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN])
#     elif dir == 8:
#         return Rnd.pick([Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,\
#                 Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]).normalized()
#     elif dir == -1:
#         var r = deg_to_rad(randi_range(0, 360))
#         return Vector2.RIGHT.rotated(r)
#     else:
#         var r = deg_to_rad(360/dir)
#         return Vector2.RIGHT.rotated(r*randi_range(0, dir-1))
# --------------------------------
