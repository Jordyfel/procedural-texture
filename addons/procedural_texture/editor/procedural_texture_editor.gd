@tool
class_name ProceduralTextureEditor
extends EditorDock

var texture: ProceduralTexture

@onready var tree: Tree = %Tree
@onready var texture_rect: TextureRect = %TextureRect

var dragging:= false


func _ready() -> void:
	tree.set_drag_forwarding(_tree_get_drag_data, _tree_can_drop_data, _tree_drop_data)


func edit(procedural_texture: ProceduralTexture) -> void:
	if procedural_texture == texture:
		return

	texture = procedural_texture

	if texture.root_node == null:
		texture.setup()

	texture_rect.texture = texture
	tree.clear()
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
	new_node.setup()
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


func _tree_get_drag_data(_at_position: Vector2) -> Variant:
	var selected:= tree.get_selected()
	if selected == null:
		return null

	var node:= texture.root_node.children[selected.get_index()]
	var preview:= Label.new()
	preview.text = node._get_name()
	tree.set_drag_preview(preview)
	return node


func _tree_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var item:= tree.get_item_at_position(at_position)
	if item == null:
		return false

	var node:= data as TextureNode
	if node == null:
		return false

	tree.drop_mode_flags = Tree.DROP_MODE_INBETWEEN
	return true


func _tree_drop_data(at_position: Vector2, data: Variant) -> void:
	var node:= data as TextureNode
	var item:= tree.get_item_at_position(at_position)
	if item == null:
		return

	var index:= texture.root_node.children.find(node)
	var drop_section:= tree.get_drop_section_at_position(at_position)
	match drop_section:
		-100:
			return
		-1:
			tree.get_root().get_child(index).move_before(item)
			_move_node(node, item.get_index() - 1)
		0:
			pass # TODO: Last child.
		1:

			tree.get_root().get_child(index).move_after(item)
			_move_node(node, item.get_index() + 1)
		2:
			pass # TODO: First child.


func _move_node(node: TextureNode, to_index: int) -> void:
	texture.root_node.children.erase(node)
	texture.root_node.children.insert(to_index, node)
	texture.update()
