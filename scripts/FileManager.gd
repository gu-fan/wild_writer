class_name FileManager extends Node

func show_save_dialog() -> String:
    var file_dialog = FileDialog.new()
    get_tree().root.add_child(file_dialog)
    # file_dialog.current_dir = 
    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    file_dialog.size = Vector2(600, 400)
    file_dialog.popup_centered()
    
    var path = await file_dialog.file_selected
    file_dialog.queue_free()
    return path

func show_open_dialog() -> String:
    var file_dialog = FileDialog.new()
    get_tree().root.add_child(file_dialog)
    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    file_dialog.size = Vector2(600, 400)
    file_dialog.popup_centered()
    
    var path = await file_dialog.file_selected
    file_dialog.queue_free()
    return path

func save_file(editor: TextEdit, file_path: String):
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_string(editor.text)
        file.close()

func new_file(editor: TextEdit):
    editor.text = ""

func open_file(editor: TextEdit, file_path: String):
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file:
        editor.text = file.get_as_text()
        file.close()
