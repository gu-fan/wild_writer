class_name DocumentManager
extends Node

signal document_changed(doc: Document)
signal document_saved(doc: Document)

# 文本操作类
class TextOperation:
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
var active_document: Document

# 生成唯一ID
func generate_id() -> String:
    return str(randi()) + "_" + str(Time.get_unix_time_from_system())

func open_document(path: String) -> Document:
    var doc = Document.new()
    doc.id = generate_id()
    doc.file_path = path
    
    if FileAccess.file_exists(path):
        doc.content = FileAccess.get_file_as_string(path)
    
    documents[doc.id] = doc
    emit_signal("document_changed", doc)
    return doc

func save_document(doc, path: String = "") -> bool:
    if path.is_empty():
        path = doc.file_path
    
    # Save the document content to the file
    var file = FileAccess.open(path, FileAccess.WRITE)
    if not file:
        return false
        
    file.store_string(doc.content)
    doc.file_path = path
    return true

func close_document(doc: Document) -> void:
    if documents.has(doc.id):
        documents.erase(doc.id)
        if active_document == doc:
            active_document = null
