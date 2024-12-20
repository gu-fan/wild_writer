class_name TestBase
extends GutTest

var editor_core: EditorCore
var test_doc_content := """
func test_function():
    print("Hello")
    return true
"""

func before_each():
    editor_core = EditorCore.new()
    add_child_autofree(editor_core)
    
func after_each():
    editor_core.queue_free()

func assert_file_contents(path: String, expected: String) -> void:
    var content = FileAccess.get_file_as_string(path)
    assert_eq(content, expected, "File contents do not match expected value")
