class_name DocumentManager
extends Node

signal file_selected(path)

signal document_changed(doc: Document)
signal document_saved(doc: Document)

const TXT_FILES =  ['*.txt,*.text,*.md,*.rst;TextFiles', '*.c,*.cpp,*.py,*.gd,*.json;CodeFiles', '*.html,*.css,*.js;WebFiles', '*.ini,*.dat;DataFiles']
const TXT_EXTS  = ["txt", "md", "rst", "py", "json", "text", "ini", "js", "gd"]

# 文本操作类
class TextOperation:
    # should be same with TextEdit. EditAction
    # none, typing, backspace, delete
    var type: String  # "insert" 或 "delete"
    var position: int
    var text: String
    var timestamp: int
    
    func _init(op_type: String, pos: int, content: String):
        type = op_type
        position = pos
        text = content
        timestamp = Time.get_unix_time_from_system()

# 文档类
class Document:
    var id: String
    var file_path: String
    var content: String
    var metadata: Dictionary
    var history: Array[TextOperation]
    var view_state: Dictionary
    
    func _init():
        id = ""
        file_path = ""
        content = ""
        metadata = {}
        history = []
        view_state = {}

var documents: Dictionary = {}
# var active_document: Document

# 生成唯一ID
func generate_id() -> String:
    return str(randi()) + "_" + str(Time.get_unix_time_from_system())
# ---------------------------
func new_document():
    var doc = Document.new()
    doc.id = generate_id()
    documents[doc.id] = doc
    return doc

func open_document(path: String) -> Document:
    if FileAccess.file_exists(path):
        var doc = Document.new()
        doc.id = generate_id()
        doc.file_path = path
        doc.content = FileAccess.get_file_as_string(path)
        documents[doc.id] = doc
        emit_signal("document_changed", doc)
        return doc
    else:
        return null

# func open_file(editor: TextEdit, file_path: String):
#     var file = FileAccess.open(file_path, FileAccess.READ)
#     if file:
#         editor.text = file.get_as_text()
#         file.close()

func save_document(doc, content, path: String = "") -> bool:
    if path.is_empty():
        path = doc.file_path
    
    # Save the document content to the file
    var file = FileAccess.open(path, FileAccess.WRITE)
    if not file:
        return false
        
    file.store_string(content)
    doc.file_path = path
    return true

# func save_file(editor: TextEdit, file_path: String):
#     var file = FileAccess.open(file_path, FileAccess.WRITE)
#     if file:
#         file.store_string(editor.text)
#         file.close()
func close_document(doc: Document) -> void:
    if documents.has(doc.id):
        documents.erase(doc.id)
        # if active_document == doc:
        #     active_document = null

# ---------------------------
func show_file_dialog(file_path='') -> void:
    var file_dialog = FileDialog.new()
    get_tree().root.add_child(file_dialog)

    var dir
    if file_path:
        dir = file_path.get_base_dir()
    else:
        dir = Editor.config.get_basic_setting("document_dir")
        dir = get_home_expanded(dir)
    
    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    file_dialog.size = Vector2(700, 400)
    file_dialog.filters = TXT_FILES

    if DirAccess.dir_exists_absolute(dir):
        if dir.right(1) != '/':
            file_dialog.current_dir = dir + '/'
            file_dialog.current_path = dir + '/'

    file_dialog.popup_centered()

    file_dialog.file_selected.connect(func(f):
        emit_signal('file_selected', f)
        file_dialog.queue_free()
    )
    file_dialog.canceled.connect(func(): 
        emit_signal('file_selected', '')
        file_dialog.queue_free()
    )

func show_directory_dialog() -> void:
    var file_dialog = FileDialog.new()
    get_tree().root.add_child(file_dialog)

    var dir = Editor.config.get_basic_setting("document_dir")
    dir = get_home_expanded(dir)
    
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
# ---------------------------
static func get_home_folded(dir:String):
    if dir.begins_with(Editor.HOME_DIR):
        return '~' + dir.substr(Editor.HOME_DIR.length())
    else:
        return dir
static func get_home_expanded(dir:String):
    if dir.left(1) == '~':
        return Editor.HOME_DIR + dir.substr(1)
    else:
        return dir

func show_save_dialog():
    var file_dialog = FileDialog.new()
    get_tree().root.add_child(file_dialog)
    
    # 使用设置中的文档目录
    var dir = Editor.config.get_basic_setting("document_dir")
    dir = get_home_expanded(dir)

    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    file_dialog.size = Vector2(700, 400)
    file_dialog.filters = TXT_FILES
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
    return file_dialog

func show_open_dialog(file_path='') -> void:
    var file_dialog = FileDialog.new()
    get_tree().root.add_child(file_dialog)

    var dir
    if file_path:
        # get the dir of file_path
        dir = file_path.get_base_dir()
    else:
        # 使用设置中的文档目录
        dir = Editor.config.get_basic_setting("document_dir")
        dir = get_home_expanded(dir)
    
    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    file_dialog.size = Vector2(700, 400)
    file_dialog.popup_centered()
    file_dialog.filters = TXT_FILES

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

# ---------------------------------------
func _test():
    print('dir expand:', get_home_expanded('~/Documents'))
    print('dir expand:', get_home_expanded('~/Documents/wikis/~'))

    print('dir folded:', get_home_folded('/Users/xrak/Documents'))
    print('dir folded:', get_home_folded('/Users/xrak/Documents/wikis/Users/xrak'))

# ---------------------------------------
func _ready():
    # _test()
    pass
