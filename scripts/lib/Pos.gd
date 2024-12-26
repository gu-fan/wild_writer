class_name Pos
# ver 3.0.1
# fix a minor bug of direction8_by_vec
# upgrade v3 to real position 3d
const GRID_SIZE = Vector2i(10, 10)
const GRID_SIZE3 = Vector3i(10, 5, 10) # each level is 5 unit
const SCALE = 1  # scaled by 2
const SCALE_V2 = Vector2i(1, 1)
const SCALE_V3 = Vector3i(1, 1, 1)
const WORLD_BASE_SIZE = GRID_SIZE * SCALE   # global pos2 scaled
const WORLD3_BASE_SIZE = GRID_SIZE3 * SCALE # global pos3 scaled
const WORLD_BASE_SIZE_INV = Vector2(1.0 / WORLD_BASE_SIZE.x, 1.0 / WORLD_BASE_SIZE.y)
const WORLD3_BASE_SIZE_INV = Vector3(1.0 / WORLD3_BASE_SIZE.x, 1.0/WORLD3_BASE_SIZE.y, 1.0 / WORLD3_BASE_SIZE.z)

# ----------------------
static func distance(pos0:Vector2, pos1:Vector2):
    return pos0.distance_to(pos1)

static func distance_sqrd(pos0:Vector2, pos1:Vector2):
    return pos0.distance_squared_to(pos1)

static func distancei(pos0:Vector2i, pos1:Vector2i):
    return abs(pos0.x - pos1.x) + abs(pos0.y - pos1.y)

static func direction2(pos0:Vector2, pos1:Vector2)->Vector2i:
    if pos0.x > pos1.x:
        return Vector2i.LEFT
    elif pos0.x < pos1.x:
        return Vector2i.RIGHT
    elif pos0.y > pos1.y:
        return Vector2i.RIGHT
    else:
        return Vector2i.LEFT

# 4 direction
# from, to
static func direction4(pos0:Vector2, pos1:Vector2)->Vector2i:
    var dir = pos0.direction_to(pos1)
    if abs(dir.x) == abs(dir.y):
        return Vector2i(1*sign(dir.x), 0)
    elif abs(dir.x) > abs(dir.y):
        return Vector2i(1*sign(dir.x), 0)
    else:
        return Vector2i(0, 1*sign(dir.y))

static func direction4_by_vec(dir:Vector2)->Vector2i:
    if abs(dir.x) == abs(dir.y):
        return Vector2i(1*sign(dir.x), 0)
    elif abs(dir.x) > abs(dir.y):
        return Vector2i(1*sign(dir.x), 0)
    else:
        return Vector2i(0, 1*sign(dir.y))

# normalize direction to 8 direction
static func direction8(pos0:Vector2, pos1:Vector2)->Vector2i:
    var deg = get_degree(pos0, pos1)
    if deg < 0: deg += 360
    var cut = round(deg / 45)
    if cut == 8: cut = 0  # there is a error this can be 8
    return dir_to_direction(cut)

static func direction8_by_vec(dir:Vector2)->Vector2i:
    var deg = rad_to_deg(dir.angle())
    if deg < 0: deg += 360
    var cut = round(deg / 45)
    if cut == 8: cut = 0  # there is a error this can be 8
    return dir_to_direction(cut)

static func direction8_degree(pos0:Vector2, pos1:Vector2)->int:
    var dir = direction8(pos0, pos1)
    return direction_degrees[dir]


static func get_degree(p0:Vector2, p1:Vector2):
    return rad_to_deg(p0.direction_to(p1).angle())

# ----------------------
#     .  
#   .   .
#     .  
static func adjacent4(pos:Vector2i, distance=1, with_origin=false)->Array:
    return adjacent_plus(pos, distance, with_origin)
#   . . .
#   .   .
#   . . .
static func adjacent8(pos:Vector2i, distance=1, with_origin=false)->Array:
    return adjacent(pos, distance, with_origin)
static func adjacent(pos:Vector2i, distance=1, with_origin=false)->Array:
    var ret = []
    for i in range(-distance, distance+1):
        for j in range(-distance, distance+1):
            if i == 0 and j == 0 and !with_origin:
                continue
            ret.append(Vector2i(pos.x+i, pos.y+j))
    return ret

# circle
# 1, 1.5, 2, 2.5, 3, 3.5
static func adjacent_sqrt(pos:Vector2i, distance=1, with_origin=false)->Array:
    var ret = []
    for i in range(-distance, distance+1):
        for j in range(-distance, distance+1):
            if i == 0 and j == 0 and !with_origin:
                continue
            if sqrt(i*i+j*j) > distance:
                continue
            ret.append(Vector2i(pos.x+i, pos.y+j))
    return ret
#     .
#   .   .
#     .
static func adjacent_plus(pos:Vector2i, distance=1, with_origin=false)->Array:
    var ret = []
    for i in range(-distance, distance+1):
        for j in range(-distance, distance+1):
            if i == 0 and j == 0 and !with_origin:
                continue
            if (abs(i)+abs(j)) > distance:
                continue
            ret.append(Vector2i(pos.x+i, pos.y+j))
    return ret

#     .
#     .
# . .   . . 
#     .
#     .
static func adjacent_line(pos:Vector2i, distance=1, with_origin=false)->Array:
    var ret = []
    for i in range(-distance, distance+1):
        for j in range(-distance, distance+1):
            if i == 0 and j == 0 and !with_origin:
                continue
            if abs(i) ==0 and abs(j) < distance:
                ret.append(Vector2i(pos.x+i, pos.y+j))
            elif abs(j) ==0 and abs(i) < distance:
                ret.append(Vector2i(pos.x+i, pos.y+j))
    return ret

#     .
#     
# .       . 
#     
#     .
static func adjacent_point(pos:Vector2i, distance=1, with_origin=false)->Array:
    var ret = []
    for i in range(-distance, distance+1):
        for j in range(-distance, distance+1):
            if i == 0 and j == 0 and !with_origin:
                continue
            if abs(i) == 0 and abs(j) == distance:
                ret.append(Vector2i(pos.x+i, pos.y+j))
            elif abs(j) ==0 and abs(i) == distance:
                ret.append(Vector2i(pos.x+i, pos.y+j))
    return ret
# ----------------------


# ----------------------
const orig_0 = [Vector2i(0,0)]
const adj4x2 = [Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2)]
const adj4 = [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]
const adj4_0 = [Vector2i(0,0), Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]
const adj8 = [
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1)]
const adj8_0 = [Vector2i(0,0), 
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1)]
const adj12 = [
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1),
    Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2)]
const adj12_0 = [Vector2i(0,0),
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1),
    Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2)]
# 12 remove top and bottom
const adj12_splash= [Vector2i(0,0),
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1),
    Vector2i(-2,0),Vector2i(2,0),]

const adj20 = [
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1),
    Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),
    Vector2i(-2,1),Vector2i(2,1),Vector2i(1,-2),Vector2i(1,2),
    Vector2i(-2,-1),Vector2i(2,-1),Vector2i(-1,-2),Vector2i(-1,2),
    ]
const adj20_0 = [Vector2i(0,0), 
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1), 
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1),
    Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),
    Vector2i(-2,1),Vector2i(2,1),Vector2i(1,-2),Vector2i(1,2),
    Vector2i(-2,-1),Vector2i(2,-1),Vector2i(-1,-2),Vector2i(-1,2),
    ]
const adj24 = [
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1),
    Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),
    Vector2i(-2,1),Vector2i(2,1),Vector2i(1,-2),Vector2i(1,2),
    Vector2i(-2,-1),Vector2i(2,-1),Vector2i(-1,-2),Vector2i(-1,2),
    Vector2i(-2,2),Vector2i(2,2),Vector2i(2,-2),Vector2i(-2,-2),
    ]
const adj24_0 = [Vector2i(0,0), 
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1), 
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1),
    Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),
    Vector2i(-2,1),Vector2i(2,1),Vector2i(1,-2),Vector2i(1,2),
    Vector2i(-2,-1),Vector2i(2,-1),Vector2i(-1,-2),Vector2i(-1,2),
    Vector2i(-2,2),Vector2i(2,2),Vector2i(2,-2),Vector2i(-2,-2),
    ]
const adj24_splash = [Vector2i(0,0), 
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1), 
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1),
    Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),
    Vector2i(-2,1),Vector2i(2,1),Vector2i(1,-2),Vector2i(1,2),
    Vector2i(-2,-1),Vector2i(2,-1),Vector2i(-1,-2),Vector2i(-1,2),
    Vector2i(-2,2),Vector2i(2,2),Vector2i(2,-2),Vector2i(-2,-2),
    Vector2i(-3,0),Vector2i(3,0),
    Vector2i(-3,1),Vector2i(-3,-1), Vector2i(3,1),Vector2i(3,-1),
    Vector2i(-4,0),Vector2i(4,0),
    ]

const adj24_splash_1 = [Vector2i(0,0), 
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1), 
    Vector2i(-1,1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1),
    Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),
    Vector2i(-2,1),Vector2i(2,1),Vector2i(1,-2),Vector2i(1,2),
    Vector2i(-2,-1),Vector2i(2,-1),Vector2i(-1,-2),Vector2i(-1,2),
    Vector2i(-2,2),Vector2i(2,2),Vector2i(2,-2),Vector2i(-2,-2),
    Vector2i(-3,0),Vector2i(3,0),
    Vector2i(-3,1),Vector2i(-3,-1), Vector2i(3,1),Vector2i(3,-1),
    Vector2i(-3,2),Vector2i(-3,-2), Vector2i(3,2),Vector2i(3,-2),
    Vector2i(-4,1),Vector2i(-4,-1), Vector2i(4,1),Vector2i(4,-1),
    Vector2i(-5,0),Vector2i(5,0),
    ]
const grid4 = [
    Vector2i(0,0), Vector2i(1,0),
    Vector2i(0,1), Vector2i(1,1),
]
const grid9 = [
    Vector2i(0,0), Vector2i(1,0), Vector2i(2,0),
    Vector2i(0,1), Vector2i(1,1), Vector2i(2,1),
    Vector2i(0,2), Vector2i(1,2), Vector2i(2,2),
]
const grid12 = [
    Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0),
    Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1),
    Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2),
]
const grid15 = [
    Vector2i(0,0), Vector2i(1,0), Vector2i(2,0),Vector2i(3,0), Vector2i(4,0),
    Vector2i(0,1), Vector2i(1,1), Vector2i(2,1),Vector2i(3,1), Vector2i(4,1),
    Vector2i(0,2), Vector2i(1,2), Vector2i(2,2),Vector2i(3,2), Vector2i(4,2),
]
const grid16 = [
    Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0),
    Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1),
    Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2),
    Vector2i(0,3), Vector2i(1,3), Vector2i(2,3), Vector2i(3,3),
]
const line5 = [
    Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0),Vector2i(4,0),
]
const _areas = {
    orig_0=orig_0,
    adj4=adj4,
    adj4_0=adj4_0,
    adj8=adj8,
    adj8_0=adj8_0,
    adj12=adj12,
    adj12_0=adj12_0,
    adj12_splash=adj12_splash,
    adj20=adj20,
    adj20_0=adj20_0,
    adj24=adj24,
    adj24_0=adj24_0,
    adj24_splash=adj24_splash,
    adj24_splash_1=adj24_splash_1,
    grid4=grid4,
    grid9=grid9,
    grid12=grid12,
    grid15=grid15,
    grid16=grid16,
    line5=line5,
}
static func get_area(type):
    return _areas.get(type, []).duplicate()

static func via_area(pos:Vector2i, area):
    var ret = []
    for p in area:
        ret.append(pos + Vector2i(p))
    return ret

static func via_adj4(pos):
    return via_area(pos, adj4)
static func via_adj8(pos):
    return via_area(pos, adj8)
static func via_adj12(pos):
    return via_area(pos, adj12)
static func via_adj24(pos):
    return via_area(pos, adj24)
static func via_adj4_0(pos):
    return via_area(pos, adj4_0)
static func via_adj8_0(pos):
    return via_area(pos, adj8_0)
static func via_adj12_0(pos):
    return via_area(pos, adj12_0)
static func via_adj24_0(pos):
    return via_area(pos, adj24_0)
# ----------------------------
# dirs: 0-7
# directions: Vector2i.RIGHT ~ Vector2i.RIGHTUP
enum {
    ZERO=-1,
    RIGHT,
    RIGHTDOWN,
    DOWN,
    LEFTDOWN,
    LEFT,
    LEFTUP,
    UP,
    RIGHTUP,
}
const directions4 = [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
const directions = [Vector2i.RIGHT,Vector2i(1,1),Vector2i.DOWN,Vector2i(-1,1),Vector2i.LEFT,Vector2i(-1,-1),Vector2i.UP,Vector2i(1,-1)]
const dirs = [0,1,2,3,4,5,6,7] # enum
const direction_degrees = {
        Vector2i.RIGHT:0, 
        Vector2i(1,1):45, 
        Vector2i.DOWN:90, 
        Vector2i(-1,1):135, 
        Vector2i.LEFT:180, 
        Vector2i(-1,-1):225, 
        Vector2i.UP:270,
        Vector2i(1,-1):315, 
        Vector2i.ZERO:0, 
    }
const direction_radians = {
        Vector2i.RIGHT:0, 
        Vector2i(1,1):PI/4, 
        Vector2i.DOWN:PI/2, 
        Vector2i(-1,1):PI*3/4, 
        Vector2i.LEFT:PI, 
        Vector2i(-1,-1):PI*5/4, 
        Vector2i.UP:PI*3/2,
        Vector2i(1,-1):PI*7/4, 
        Vector2i.ZERO:0, 
    }
const direction_dirs = {
        Vector2i.RIGHT:0, 
        Vector2i(1,1):1, 
        Vector2i.DOWN:2, 
        Vector2i(-1,1):3, 
        Vector2i.LEFT:4, 
        Vector2i(-1,-1):5, 
        Vector2i.UP:6,
        Vector2i(1,-1):7, 
        Vector2i.ZERO:-1, 
    }
const dir_directions = {
        0:Vector2i.RIGHT, 
        1:Vector2i(1,1), 
        2:Vector2i.DOWN, 
        3:Vector2i(-1,1), 
        4:Vector2i.LEFT, 
        5:Vector2i(-1,-1), 
        6:Vector2i.UP,
        7:Vector2i(1,-1), 
        -1:Vector2i.ZERO, 
    }
const dir_names = {
        0:'RIGHT',
        1:'RIGHTDOWN',
        2:'DOWN',
        3:'LEFTDOWN',
        4:'LEFT',
        5:'LEFTUP',
        6:'UP',
        7:'RIGHTUP',
        -1:'ZERO',
    }
const direction_names = {
        Vector2i.RIGHT:'RIGHT',
        Vector2i(1,1):'RIGHTDOWN',
        Vector2i.DOWN:'DOWN',
        Vector2i(-1,1):'LEFTDOWN',
        Vector2i.LEFT:'LEFT',
        Vector2i(-1,-1):'LEFTUP',
        Vector2i.UP:'UP',
        Vector2i(1,-1):'RIGHTUP',
        Vector2i.ZERO:'ZERO',
    }
const name_directions = {
        'right':Vector2i.RIGHT, 
        'bottom_right':Vector2i(1,1), 
        'bottom':Vector2i.DOWN, 
        'bottom_left':Vector2i(-1,1), 
        'left':Vector2i.LEFT, 
        'up_left':Vector2i(-1,-1), 
        'up':Vector2i.UP,
        'up_right':Vector2i(1,-1), 
        'zero':Vector2i.ZERO, 
    }
const degree_directions = {
        0:Vector2i.RIGHT, 
        45:Vector2i(1,1), 
        90:Vector2i.DOWN, 
        135:Vector2i(-1,1), 
        180:Vector2i.LEFT, 
        225:Vector2i(-1,-1), 
        270:Vector2i.UP,
        315:Vector2i(1,-1), 
    }
const direction_shorts = {
        Vector2i.RIGHT:'R',
        Vector2i(1,1):'RT',
        Vector2i.DOWN:'B',
        Vector2i(-1,1):'LB',
        Vector2i.LEFT:'L',
        Vector2i(-1,-1):'LT',
        Vector2i.UP:'T',
        Vector2i(1,-1):'RT',
        Vector2i.ZERO:'Z',
    }

const direction_symbols = {
        Vector2i.RIGHT:'→',
        Vector2i(1,1):'RT',
        Vector2i.DOWN:'↓',
        Vector2i(-1,1):'LB',
        Vector2i.LEFT:'←',
        Vector2i(-1,-1):'LT',
        Vector2i.UP:'↑',
        Vector2i(1,-1):'RT',
        Vector2i.ZERO:'o',
    }
const direction_arrows = {
        Vector2i.RIGHT:'>',
        Vector2i(1,1):'RT',
        Vector2i.DOWN:'V',
        Vector2i(-1,1):'LB',
        Vector2i.LEFT:'<',
        Vector2i(-1,-1):'LT',
        Vector2i.UP:'^',
        Vector2i(1,-1):'RT',
        Vector2i.ZERO:'o',
    }
# -----------
static func dir_to_direction(dir)->Vector2i:
    return dir_directions.get(int(dir), Vector2i.ZERO)

static func direction_to_dir(direction)->int:
    return direction_dirs.get(direction as Vector2i, -1)

# -----------
static func area_rotated(pos:Vector2, area:Array, direction):
    if area.size() == 0: return []
    var rotated = {}
    for p in area:
        p = p as Vector2
        # p=p+Vector2(0.1, 0.1) # wrong placement
        var rotd = p.rotated(direction_radians[direction as Vector2i]).round() + pos
        # rotated.append(rotd as Vector2i)
        rotated[rotd as Vector2i] = true
    
    return rotated.keys()

static func vec_rotated(vec:Vector2, direction):
    return vec.rotated(direction_radians[direction as Vector2i]).round() as Vector2i
# -----------
static func is_adj4(p0:Vector2i, p1:Vector2i):
    if p0.x == p1.x and abs(p0.y - p1.y) == 1:
        return true
    elif p0.y == p1.y and abs(p0.x - p1.x) == 1:
        return true
    else:
        return false

static func is_adj4_0(p0:Vector2i, p1:Vector2i):
    if p0.x == p1.x and p0.y == p1.y:
        return true
    elif p0.x == p1.x and abs(p0.y - p1.y) == 1:
        return true
    elif p0.y == p1.y and abs(p0.x - p1.x) == 1:
        return true
    else:
        return false

static func is_adj8(p0:Vector2i, p1:Vector2i):
    if p0.x == p1.x and abs(p0.y - p1.y) == 1:
        return true
    elif p0.y == p1.y and abs(p0.x - p1.x) == 1:
        return true
    elif abs(p0.x - p1.x) == 1 and abs(p0.y - p1.y) == 1:
        return true
    else:
        return false

static func is_adj8_0(p0:Vector2i, p1:Vector2i):
    if p0.x == p1.x and p0.y == p1.y:
        return true
    elif p0.x == p1.x and abs(p0.y - p1.y) == 1:
        return true
    elif p0.y == p1.y and abs(p0.x - p1.x) == 1:
        return true
    elif abs(p0.x - p1.x) == 1 and abs(p0.y - p1.y) == 1:
        return true
    else:
        return false

static func is_adj4_dis(p0, p1,dis=2):
    if p0.x == p1.x and abs(p0.y - p1.y) == dis:
        return true
    elif p0.y == p1.y and abs(p0.x - p1.x) == dis:
        return true
    else:
        return false

static func is_adj4_norm(p0, p1): # normalize extending on x-axis and y-axis
    if p0.x == p1.x and abs(p0.y - p1.y) >= 1:
        return true
    elif p0.y == p1.y and abs(p0.x - p1.x) >= 1:
        return true
    else:
        return false

static func get_adj4_norm(p0, p1):
    if p0.x == p1.x and abs(p0.y - p1.y) >= 1:
        if p1.y > p0.y:
            return Vector2i(0,1)
        else:
            return Vector2i(0,-1)
    elif p0.y == p1.y and abs(p0.x - p1.x) >= 1:
        if p1.x > p0.x:
            return Vector2i(1,0)
        else:
            return Vector2i(-1,0)
    else:
        return Vector2i(0,0)


# -----------
static func is_any_adj8(pos, poses):
    for p in poses:
        if is_adj8(p, pos):
            return true
    return false

static func is_any_adj4(pos, poses):
    for p in poses:
        if is_adj4(p, pos):
            return true
    return false

# -----------
const signs = [Vector2i(1,1), Vector2i(-1,1), Vector2i(-1,-1), Vector2i(1,-1)]
# ----------------------------------

static func between(pos0:Vector2, pos1:Vector2):
    var pos = pos0
    var dir = pos1 - pos0
    var dist = dir.length()
    dir = dir.normalized()
    var pos_list = {}
    for i in range(dist):
        pos += dir
        pos_list[pos as Vector2i] = true

    for off in [Vector2(0.5, 0.5)]:
    # for off in [Vector2(0.2, 0.2), Vector2(0.8,0.8), Vector2(0.2,0.8), Vector2(0.8,0.2)]:
        for i in range(dist):
            pos += dir+off
            pos_list[pos as Vector2i] = true

    return pos_list.keys()


static func supercover_line(p0, p1):
    var dx = p1.x-p0.x
    var dy = p1.y-p0.y
    var nx = abs(dx)
    var ny = abs(dy)
    var sign_x = 1 if dx > 0 else -1
    var sign_y = 1 if dy > 0 else -1

    var p = Vector2(p0.x, p0.y)
    var points = [Vector2i(p.x, p.y)]
    var ix =0
    var iy =0
    while ix < nx or iy < ny:
        var decision = (1 + 2*ix) * ny - (1 + 2*iy) * nx
        if decision == 0:
            # next step is diagonal
            p.x += sign_x
            p.y += sign_y
            ix+=1
            iy+=1
        elif decision < 0:
            # next step is horizontal
            p.x += sign_x
            ix+=1
        else:
            # next step is vertical
            p.y += sign_y
            iy+=1

        points.append(Vector2i(p.x, p.y))

    return points


# ---------------------------------------------------
static func get_rect2i(p0:Vector2i, p1:Vector2i): # inclusive, grow at right/bottom
    var sz = Vector2i((p1.x - p0.x), (p1.y - p0.y))
    var size = Vector2i(abs(sz.x)+1, abs(sz.y)+1)
    var pos = Vector2i.ZERO
    if sz.x < 0: # p1.x < p0.x
        pos.x = p1.x
    else:
        pos.x = p0.x

    if sz.y < 0: # p1.x < p0.x
        pos.y = p1.y
    else:
        pos.y = p0.y

    return Rect2i(pos, size)

static func get_points_inside(rect:Rect2i): # same as Rect.has_point
    var ret = []
    for i in rect.size.x:
        for j in rect.size.y:
            ret.append(Vector2i(i, j) + rect.position)
    return ret
    

# ---------------------------------------------------
# ?
static func is_in_distancei(p0:Vector2i, p1:Vector2i, dis:float):
    return  distancei(p0, p1) <= dis

static func is_surrounded(p, pts):
    for adjp in via_adj4(p):
        if not adjp in pts:
            return false
    return true

# ---------------------------------------------------
# Bresenham line
# https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
# this is NOT always p0 from p1
static func _line_low(x0:int, y0:int, x1:int, y1:int):
    var dx = x1 - x0
    var dy = y1 - y0
    var yi = 1
    if dy < 0: 
        yi = -1
        dy = -dy
    var _d = 2*dy - dx
    var y = y0

    var ret = []
    for x in range(x0, x1+1):
        ret.append(Vector2i(x, y))
        if _d > 0:
            y = y + yi
            _d = _d + (2 * (dy-dx))
        else:
            _d = _d + 2*dy

    return ret

static func _line_high(x0:int, y0:int, x1:int, y1:int):
    var dx = x1 - x0
    var dy = y1 - y0
    var xi = 1
    if dx < 0: 
        xi = -1
        dx = -dx
    var _d = 2*dx - dy
    var x = x0

    var ret = []
    for y in range(y0, y1+1):
        ret.append(Vector2i(x, y))
        if _d > 0:
            x = x + xi
            _d = _d + (2 * (dx-dy))
        else:
            _d = _d + 2*dx

    return ret

static func line(p0:Vector2i, p1:Vector2i):
    var x0 = p0.x
    var y0 = p0.y
    var x1 = p1.x
    var y1 = p1.y
    if abs(y1 - y0) < abs(x1 - x0):
        if x0 > x1:
            return _line_low(x1, y1, x0, y0)
        else:
            return _line_low(x0, y0, x1, y1)
    else:
        if y0 > y1:
            return _line_high(x1, y1, x0, y0)
        else:
            return _line_high(x0, y0, x1, y1)

# seems same with line
static func line3(start:Vector2, stop:Vector2):
  var diff = stop - start
  var increment = sign(diff)
  var delta = abs(diff) * 2
  var current = start

  var ret = [start]
  if delta.x >= delta.y:
    var error = delta.y - delta.x / 2
    while current.x != stop.x:
      if error > 0 or (error == 0 and increment.x > 0):
        error -= delta.x
        current.y += increment.y
      error += delta.y
      current.x += increment.x
      # yield current
      # return current
      ret.append(Vector2i(current))
  else:
    var error = delta.x - delta.y / 2
    while current.y != stop.y:
      if error > 0 or (error == 0 and increment.y > 0):
        error -= delta.y
        current.x += increment.x
      error += delta.x
      current.y += increment.y
      # yield current
      # return current
      ret.append(Vector2i(current))
  return ret
# ---------------------------------------------------
# https://www.redblobgames.com/grids/line-drawing/
# performance is merly the same with Bresenham
# this is always p0 from p1
static func diagonal_distance(p0, p1) -> float:
    var dx = p1.x - p0.x
    var dy = p1.y - p0.y
    return max(abs(dx), abs(dy))

static func line2(p0:Vector2, p1:Vector2):
    var points = []
    var N = diagonal_distance(p0, p1)
    for step in N + 1:
        var t = 0.0 if N == 0 else step / N
        points.append(Vector2i(p0.lerp(p1, t).round()))
    return points

# p0 p1 has same axis, return line between them
static func line_between(p0:Vector2i, p1:Vector2i):
    var ret = []
    if p0.x == p1.x:
        var pmin = min(p0.y, p1.y)
        var pmax = max(p0.y, p1.y)
        for i in pmax - pmin - 1:
            ret.append(Vector2i(p0.x, pmin + i + 1))
    elif p0.y == p1.y:
        var pmin = min(p0.x, p1.x)
        var pmax = max(p0.x, p1.x)
        for i in pmax - pmin - 1:
            ret.append(Vector2i(pmin + i + 1, p0.y))
    return ret

        
# ---------------------------------------------------
static func get_random_points(pts, count, _constrain_filter=null):
    return Rnd.some(pts, count, _constrain_filter)

static func get_random_pos_in_area(_from, _to, _area, _constrain_filter=null):
    if _area is String: _area = get_area(_area)
    var direction4 = Pos.direction4(_from, _to)
    var _random_area = Pos.area_rotated(_to, _area, direction4)
    return Rnd.pick(_random_area, _constrain_filter)

static func get_random_poses_in_area(_from, _to, _area, _count=3, _constrain_filter=null):
    if _area is String: _area = get_area(_area)
    var direction4 = Pos.direction4(_from, _to)
    var _random_area = Pos.area_rotated(_to, _area, direction4)
    return Rnd.some(_random_area, _count, _constrain_filter)

static func get_nearest(pos, poses):
    var min = 999
    var min_p = null
    for p in poses:
        var dis = Pos.distancei(pos, p) 
        if dis < min:
            min_p = p
            min = dis
    return min_p

static func get_farthest(pos, poses):
    var max = 999
    var max_p = null
    for p in poses:
        var dis = Pos.distancei(pos, p) 
        if dis > max:
            max_p = p
            max = dis
    return max_p

static func get_total_distance(pts):
    var dis = 0
    for i in pts.size() - 1:
        dis += distance(pts[i], pts[i+1])
    return dis

# ---------------------------------
static func extend_poses(poses, rng=1):
    var _ret = {}

    var _dup = {}
    for p in poses:
        for n in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]:
            for i in rng:
                var p_n = p + n * (i+1)
                _dup[p_n] = 1

    _ret.merge(_dup)

    return _ret


# ---------------------------------------
# bouncing vec from ground, in any direction
static func get_bounce_over_ground(vec, spread=60):
    var bon = vec.bounce(Vector2.RIGHT)
    var bon_posi = Vector2(bon.x, -abs(bon.y))
    var bon_angle = bon_posi.angle()
    var ang_min = bon_angle + deg_to_rad(-spread)
    var ang_max = bon_angle + deg_to_rad(spread)

    var vec_len = vec.length()

    var l_min = Vector2.from_angle(ang_min) * vec_len
    var l_max = Vector2.from_angle(ang_max) * vec_len
    var has_horz_proj = false
    var horz_proj_vec = Vector2(0,0)
    if l_min.y > 0: 
        l_min.y = 0
        has_horz_proj = true
        horz_proj_vec= l_min
    if l_max.y > 0: 
        l_max.y = 0
        has_horz_proj = true
        horz_proj_vec= l_max
    ang_min = l_min.angle()
    ang_max = l_max.angle()
    if ang_min <= 0: ang_min = 2 * PI + ang_min
    if ang_max <= 0: ang_max = 2 * PI + ang_max 
    
    var ang_cnt = (ang_min + ang_max) / 2.0
    var l_cnt = Vector2.from_angle(ang_cnt) * vec_len
    var spread_ang = rad_to_deg(abs(ang_max - ang_cnt))
    return {
        bon_dir=bon_posi,
        cnt_dir=l_cnt,
        cnt_spread=spread_ang,
        has_horz=has_horz_proj,
        horz_dir=horz_proj_vec,
        min_dir=l_min,
        max_dir=l_max,
    }

# ----------------------------------------------------------------
# world to grid calc
# round is the same as snapped
# round
# -5.5 -> -6 ,  5.5 -> 6
# int (truncation)  # use int, as the 51 & 59 -> 5, -51 & -59 -> -5
# -5.5 -> -5  , 5.5 -> 5
# ceil
# -5.5 -> -5  5.5 -> 6
# floor
# -5.5 -> -6   5.5-> 5
# -------------------------------------
static func world_to_grid(wpos:Vector2, scale=1)-> Vector2i:
    # return Vector2i(round(wpos.x*WORLD_BASE_SIZE_INV.x), round(wpos.y*WORLD_BASE_SIZE_INV.y))
    return Vector2i(int(wpos.x*WORLD_BASE_SIZE_INV.x / scale), int(wpos.y*WORLD_BASE_SIZE_INV.y / scale))
static func grid_to_world(gpos:Vector2, scale=1)-> Vector2:
    return Vector2(gpos.x*WORLD_BASE_SIZE.x*scale , gpos.y*WORLD_BASE_SIZE.y*scale)
static func grid_to_worldi(gpos:Vector2, scale)-> Vector2i:
    return Vector2i(gpos.x*WORLD_BASE_SIZE.x * scale , gpos.y*WORLD_BASE_SIZE.y * scale)
# -------------------------------
static func world3_to_grid3(wpos:Vector3, scale=1)-> Vector3i:
    return Vector3i(int(wpos.x*WORLD3_BASE_SIZE_INV.x / scale), int(wpos.y*WORLD3_BASE_SIZE_INV.y / scale), int(wpos.z*WORLD3_BASE_SIZE_INV.z / scale))
static func grid3_to_world3(wpos:Vector3, scale=1)-> Vector3:
    return Vector3(wpos.x*WORLD3_BASE_SIZE.x * scale, wpos.y*WORLD3_BASE_SIZE.y * scale, wpos.z*WORLD3_BASE_SIZE.z * scale)
# -------------------------------
# static func world3_to_grid_s(wpos:Vector3)-> Vector2i:
#     return Vector2i(Vector2(wpos.x, wpos.z).snapped(GRID_SIZE)) / 10
# static func world3_to_grid3d(wpos:Vector3)-> Vector2i:
#     return Vector2i(round(wpos.x/GRID_SIZE.x), round(wpos.z/GRID_SIZE.y))
# -----------------------
static func world3_to_grid2(wpos:Vector3, scale=1)-> Vector2i:
    return Vector2i(int(wpos.x*WORLD_BASE_SIZE_INV.x / scale), int(wpos.z*WORLD_BASE_SIZE_INV.y / scale))
static func grid2_to_world3(gpos:Vector2, scale=1)-> Vector3:
    return Vector3(gpos.x*WORLD3_BASE_SIZE.x * scale, 0, gpos.y*WORLD3_BASE_SIZE.z * scale)
static func world2_to_grid3(wpos:Vector2, scale=1)-> Vector3i:
    return Vector3i(int(wpos.x*WORLD3_BASE_SIZE_INV.x/scale), 0, int(wpos.y*WORLD3_BASE_SIZE_INV.z / scale))
static func grid3_to_world2(gpos:Vector3, scale=1)-> Vector2:
    return Vector2(gpos.x*WORLD_BASE_SIZE.x * scale, gpos.z*WORLD_BASE_SIZE.y * scale)
# -------------------------------------
static func world(gpos:Vector2, scale=1)-> Vector2:
    return grid_to_world(gpos, scale)
static func grid(gpos:Vector2, scale=1)-> Vector2i:
    return world_to_grid(gpos, scale)

static func world3(gpos:Vector3, scale=1)-> Vector3:
    return grid3_to_world3(gpos, scale)
static func grid3(gpos:Vector3, scale=1)-> Vector3i:
    return world3_to_grid3(gpos, scale)

# snap the world position to each cell
static func world_snapped(wpos:Vector2, scale=1) -> Vector2:
    return wpos.snapped(WORLD_BASE_SIZE * scale)
static func world3_snapped(wpos:Vector3, scale=1) -> Vector3:
    return wpos.snapped(WORLD3_BASE_SIZE * scale)
# static func world_move_grid(wpos:Vector2, dir:Vector2i) -> Vector2:
#     return grid_to_world(world_to_grid(wpos) + dir)
# -------------------------------------
