extends Node
# 1.6 refactored

var _raw = {}

func load(raw_path: String, silent: bool = false):
    var parsed = _parse_raw_path(raw_path)
    var path = parsed[0]
    var key = parsed[1]
    
    if key == '':
        return null
    
    if not _raw.has(path):
        _raw[path] = _load_raw_file(path, silent)
    
    if key:
        return _get_nested_value(_raw[path], key)
    else:
        return _raw[path].duplicate(true)

func set_raw(raw_path: String, val):
    var parsed = _parse_raw_path(raw_path)
    var path = parsed[0]
    var key = parsed[1]
    
    if not _raw.has(path):
        _raw[path] = {}
    
    if key:
        _set_nested_value(_raw[path], key, val)
    else:
        _raw[path] = val

func get_raw(raw_path: String):
    return load(raw_path)

# Helper functions
func _parse_raw_path(raw_path: String) -> Array:
    var parts = raw_path.split(':', true, 1)
    return [parts[0], parts[1] if parts.size() > 1 else null]

func _load_raw_file(path: String, silent: bool) -> Dictionary:
    var file_path = "res://raw/%s.gd" % path
    if ResourceLoader.exists(file_path):
        return load(file_path).data()
    else:
        if not silent:
            printerr('Raw.load(): path not found: ', file_path)
        return {}

func _get_nested_value(data, key: String):
    var keys = key.split('.')
    var result = data
    
    for k in keys:
        if result is Array:
            var index = int(k)
            if index < 0 or index >= result.size():
                return null
            result = result[index]
        elif result is Dictionary:
            if not result.has(k):
                return null
            result = result[k]
        else:
            return null
    
    return result.duplicate(true) if result is Dictionary or result is Array else result

func _set_nested_value(data: Dictionary, key: String, value):
    var keys = key.split('.')
    var current = data
    
    for i in range(keys.size() - 1):
        var k = keys[i]
        if not current.has(k) or not current[k] is Dictionary:
            current[k] = {}
        current = current[k]
    
    current[keys[-1]] = value
