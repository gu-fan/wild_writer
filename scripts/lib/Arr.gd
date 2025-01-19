class_name Arr
# ver 2.0.1 add reversed

# methods: map, filter, reduce already in Array now
# here provides map/filter/reduce with index
# distinct, single, subtract, intersect, merge, sum, mul,
# any, all, next, prev, wrap_next, wrap_prev

# return not duplicate ones
static func unique(arr):
    return arr.filter(func(val): return arr.find(val) == arr.rfind(val))

# remove duplicate
static func distinct(arr):
    return single(arr)
    # var will_rmv = []
    # for i in arr.size():
    #     var a = arr[i]
    #     var r_i = arr.rfind(a)
    #     while r_i != i and (not r_i in will_rmv):
    #         will_rmv.append(r_i)
    #         r_i = arr.rfind(a)
    # will_rmv.sort()
    # will_rmv.reverse()
    # for i in will_rmv:
    #     arr.remove_at(i)
    # return arr
static func single(arr):
    return filter(arr, func(val, idx): return arr.find(val) == idx)
# --------------------------------
static func subtract(i_arr, s_arr):
    return i_arr.filter(func(val): return !s_arr.has(val))

static func intersect(i_arr, s_arr):
    return i_arr.filter(func(val): return s_arr.has(val))

static func merge(i_arr, s_arr):
    return distinct(i_arr + s_arr)
# --------------------------------
static func sum(arr):
    return arr.reduce(func(acc, val): return acc + val, 0)

static func mul(arr):
    return arr.reduce(func(acc, val): return acc * val, 1)


static func is_include_all(a_arr, b_arr): # b is included by a, all
    for v in b_arr:
        if not v in a_arr:
            return false
    return true

static func is_include_any(a_arr, b_arr): # b is included by a, any
    for v in b_arr:
        if v in a_arr:
            return true
    return false
# ------------------------------------
# has value, index
static func map(map_func, arr):
    var ret_arr = []
    for i in arr.size():
        var val = arr[i]
        var args = [val, i]
        ret_arr.append(map_func.callv(args))
    return ret_arr

# has value, index
static func filter(arr, filter_func, arg=null):
    var ret_arr = []
    for i in arr.size():
        var val = arr[i]
        var args = [val, i]
        if arg: args.append(arg)
        if filter_func.callv(args):
            ret_arr.append(val)
    return ret_arr

# has value, index
static func reduce(arr, reduce_func, first=null):
    var acc = first
    var start = 0
    if acc == null:
        if arr.size():
            acc = arr[0]
        else:
            acc = null
        start = 1
    for i in range(start, arr.size()):
        var val = arr[i]
        var args = [val, i]
        args.push_front(acc)
        acc = reduce_func.callv(args)
    return acc

# ----------------------------------
static func any(arr, method):
    return arr.any(method)
static func all(arr, method):
    return arr.all(method)
# ------------------------------------
# find next/prev val in arr
# does not consider duplicate value
# which will jump off the duplicate area as using rfind
# should use Arr.single(arr) manually if needed
static func wrap_next(arr, val):
    var idx = arr.rfind(val)
    if idx == -1:
        return arr[0]
    elif idx == arr.size() - 1:
        return arr[0]
    return arr[idx + 1]

static func wrap_prev(arr, val):
    var idx = arr.find(val)
    if idx == -1:
        return arr[0]
    elif idx == 0:
        return arr[arr.size() - 1]
    return arr[idx - 1]

# return null if end or -1
static func next(arr, val):
    var idx = arr.rfind(val)
    if idx == -1:
        return null
    elif idx == arr.size() - 1:
        return null
    return arr[idx + 1]

static func prev(arr, val):
    var idx = arr.find(val)
    if idx == -1:
        return null
    elif idx == 0:
        return null
    return arr[idx - 1]

static func wrap_index(idx, arr, count=1):
    return wrapi(idx+count, 0, arr.size())
# ------------------------------------
static func repeat(arr, n):
    if arr.size() == 0: return []
    if n == 0: return []
    var con = []
    for i in n:
        con.append_array(arr.duplicate(true))
    return con
# ------------------------------------
# for inventory useage
# [null, null,null] -> [v, null, null]
# [] - > [v]
# [v0] - > [v0, v]
static func set_or_append_first_non_empty(arr, nval):
    var i = 0
    var is_set = false
    for v in arr:
        if v == null or v == '':
            arr[i] = nval
            is_set = true
            break
        i+=1
    if !is_set: arr.append(nval)

# ------------------------------------
static func reversed(arr):
    var _n = arr.duplicate()
    _n.reverse()
    return _n
