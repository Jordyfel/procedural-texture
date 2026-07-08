@tool
class_name ProceduralTextureEditorPlugin
extends EditorPlugin

var editor: ProceduralTextureEditor


func _enter_tree() -> void:
	editor = load("uid://ck717dp7o5kue").instantiate()
	add_dock(editor)
	editor.close()


func _exit_tree() -> void:
	remove_dock(editor)
	editor.queue_free()
	editor = null


func _get_plugin_name() -> String:
	return "Procedural Texture Editor"


func _handles(object: Object) -> bool:
	return object is ProceduralTexture


func _make_visible(visible: bool) -> void:
	if visible:
		editor.make_visible()


func _edit(object: Object) -> void:
	if object == null:
		return

	editor.edit(object as ProceduralTexture)
