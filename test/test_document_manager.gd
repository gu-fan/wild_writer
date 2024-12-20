class_name TestDocumentManager
extends TestBase

func test_create_document():
    var doc = editor_core.document_manager.create_document()
    assert_not_null(doc)
    assert_eq(doc.content, "")

func test_load_document():
    var test_file = "res://tests/fixtures/test.txt"
    var doc = editor_core.document_manager.open_document(test_file)
    assert_eq(doc.content, test_doc_content)
    assert_eq(doc.file_path, test_file)

func test_save_document():
    var doc = editor_core.document_manager.create_document()
    doc.content = "test content"
    
    var temp_path = "user://temp_test.txt"
    var result = editor_core.document_manager.save_document(doc, temp_path)
    assert_true(result)
    assert_file_exists(temp_path)
    assert_file_contents(temp_path, "test content")
