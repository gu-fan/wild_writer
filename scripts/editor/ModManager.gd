class_name ModManager
extends Node

# ~/.local/share/godot/app_userdata/wild_writer/backup.txt
const MODS_PATH = "user://mods/"
var loaded_mods: Dictionary = {}

func load_mods() -> void:
    var dir = DirAccess.open(MODS_PATH)
    if not dir:
        DirAccess.make_dir_absolute(MODS_PATH)
        return
        
    dir.list_dir_begin()
    var mod_dir = dir.get_next()
    
    while mod_dir != "":
        if dir.current_is_dir() and not mod_dir.begins_with("."):
            load_mod(mod_dir)
        mod_dir = dir.get_next()
    dir.list_dir_end()

func load_mod(mod_name: String) -> void:
    var mod_path = MODS_PATH.path_join(mod_name)
    var mod_script = mod_path.path_join("main.gd")
    
    if FileAccess.file_exists(mod_script):
        var script = load(mod_script)
        if script:
            var mod_instance = script.new()
            if mod_instance.has_method("init"):
                # Pass the editor_core reference to the mod
                mod_instance.init(get_parent())
                loaded_mods[mod_name] = mod_instance
                get_parent().emit_signal("mod_loaded", mod_name)

func unload_mod(mod_name: String) -> void:
    if loaded_mods.has(mod_name):
        var mod = loaded_mods[mod_name]
        if mod.has_method("cleanup"):
            mod.cleanup()
        loaded_mods.erase(mod_name)
        get_parent().emit_signal("mod_unloaded", mod_name)

func get_loaded_mods() -> Array:
    return loaded_mods.keys() 
