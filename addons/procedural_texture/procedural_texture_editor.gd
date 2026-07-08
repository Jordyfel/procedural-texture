@tool
class_name ProceduralTextureEditor
extends EditorDock

var texture: ProceduralTexture

@onready var tree: Tree = %Tree
@onready var texture_rect: TextureRect = %TextureRect

var dragging:= false


func edit(procedural_texture: ProceduralTexture) -> void:
	if procedural_texture == texture:
		return

	texture = procedural_texture

	# TODO: Move to factory method?
	if texture.root_node == null:
		texture.root_node = TextureNode.new()
		texture.root_node.texture = texture.root_texture

	texture_rect.texture = texture
	var tree_root:= tree.create_item()
	tree_root.set_text(0, "Procedural Texture")
	for node in texture.root_node.children:
		var item:= tree.create_item(tree_root)
		item.set_text(0, node._get_name())


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	var selected:= tree.get_selected()
	if selected == null:
		return

	var mb:= event as InputEventMouseButton
	var mm:= event as InputEventMouseMotion

	if mb != null and mb.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		if mb.is_pressed():
			dragging = true
		elif mb.is_released():
			dragging = false

	if mm != null and dragging and not mm.relative.is_zero_approx():
		var node:= texture.root_node.children[selected.get_index()]
		var rect_scale:= Vector2(texture.width, texture.height) / texture_rect.size
		node.position = mm.position * rect_scale
		EditorInterface.set_object_edited(texture, true)


func _on_texture_rect_mouse_exited() -> void:
	dragging = false


func _on_add_button_pressed() -> void:
	var new_node:= CircleShape.new()
	texture.root_node.children.append(new_node)
	new_node.changed.connect(texture.update)
	texture.update()
	var item = tree.create_item()
	item.set_text(0, new_node._get_name())


func _on_tree_item_selected() -> void:
	var selected:= tree.get_selected()
	if selected.get_parent() == null:
		return

	var node:= texture.root_node.children[selected.get_index()]
	EditorInterface.edit_resource(node)


func _on_remove_button_pressed() -> void:
	var selected:= tree.get_selected()
	if selected.get_parent() == null:
		return

	texture.root_node.children.remove_at(selected.get_index())
	texture.update()
	EditorInterface.edit_resource(texture)
	EditorInterface.set_object_edited(texture, true)
	selected.free()
