class_name FileManager extends Node

signal file_selected(path)

func show_save_dialog() -> void:
    var file_dialog = FileDialog.new()
    get_tree().root.add_child(file_dialog)
    
    # 使用设置中的文档目录
    var dir = SettingManager.get_basic_setting("document_dir")
    dir = dir.replace("~", OS.get_environment("HOME"))  # 展开 ~ 到用户目录

    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    file_dialog.size = Vector2(700, 400)
    file_dialog.popup_centered()

    if DirAccess.dir_exists_absolute(dir):
        if dir.right(1) != '/':
            file_dialog.current_dir = dir + '/'
            file_dialog.current_path = dir + '/'
        # create file with current date and hour and minute
        var current_time = Time.get_datetime_string_from_system()
        var file_name = current_time.replace("-", "_").replace(" ", "_").replace(":", "_") + ".txt"
        file_dialog.current_file = file_name
    
    file_dialog.file_selected.connect(func(f):
        emit_signal('file_selected', f)
        file_dialog.queue_free()
    )
    file_dialog.canceled.connect(func(): 
        emit_signal('file_selected', '')
        file_dialog.queue_free()
    )


func show_open_dialog(file_path='') -> void:
    var file_dialog = FileDialog.new()
    get_tree().root.add_child(file_dialog)

    var dir
    if file_path:
        # get the dir of file_path
        dir = file_path.get_base_dir()
    else:
        # 使用设置中的文档目录
        dir = SettingManager.get_basic_setting("document_dir")
        dir = dir.replace("~", OS.get_environment("HOME"))  # 展开 ~ 到用户目录
    
    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    file_dialog.size = Vector2(700, 400)
    file_dialog.popup_centered()

    if DirAccess.dir_exists_absolute(dir):
        if dir.right(1) != '/':
            file_dialog.current_dir = dir + '/'
            file_dialog.current_path = dir + '/'

    file_dialog.file_selected.connect(func(f):
        emit_signal('file_selected', f)
        file_dialog.queue_free()
    )
    file_dialog.canceled.connect(func(): 
        emit_signal('file_selected', '')
        file_dialog.queue_free()
    )

func save_file(editor: TextEdit, file_path: String):
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_string(editor.text)
        file.close()

func save_text(text: String, file_path: String):
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_string(text)
        file.close()

func new_file(editor: TextEdit):
    editor.text = ""

func open_file(editor: TextEdit, file_path: String):
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file:
        editor.text = file.get_as_text()
        file.close()

func show_directory_dialog() -> void:
    var file_dialog = FileDialog.new()
    get_tree().root.add_child(file_dialog)

    var dir = SettingManager.get_basic_setting("document_dir")
    dir = dir.replace("~", OS.get_environment("HOME"))  # 展开 ~ 到用户目录
    
    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
    file_dialog.size = Vector2(700, 400)
    file_dialog.popup_centered()

    if DirAccess.dir_exists_absolute(dir):
        if dir.right(1) != '/':
            file_dialog.current_dir = dir + '/'
            file_dialog.current_path = dir + '/'
    
    file_dialog.dir_selected.connect(func(f):
        emit_signal('file_selected', f)
        file_dialog.queue_free()
    )
    file_dialog.canceled.connect(func(): 
        emit_signal('file_selected', '')
        file_dialog.queue_free()
    )
