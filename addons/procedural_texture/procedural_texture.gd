@tool
class_name ProceduralTexture
extends Texture2D

@export var height:= 2:
	set(value):
		height = value
		_on_size_changed()

@export var width:= 2:
	set(value):
		width = value
		_on_size_changed()

@export var background_color:= Color.WHITE:
	set(value):
		background_color = value
		if not initialized:
			return

		_redraw()

@export_storage var root_node: TextureNode
@export_storage var shader: Shader

const MAX_SHAPE_COUNT = 16

var initialized:= false

var texture: RID
var material: RID
var dummy_source: RID

var instance_count:= 0


func _init() -> void:
	var image:= Image.create_empty(2, 2, false, Image.Format.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	dummy_source = RenderingServer.texture_2d_create(image)
	texture = dummy_source
	material = RenderingServer.material_create()


func setup() -> void:
	root_node = TextureNode.new()
	shader = load("uid://cki66x75vn1uk")
	_initialize()


func _initialize() -> void:
	initialized = true
	RenderingServer.material_set_shader(material, shader.get_rid())
	var bg:= Oklab.linear_to_oklab(background_color.srgb_to_linear())
	texture = RenderingServer.texture_drawable_create(
		width,
		height,
		RenderingServer.TEXTURE_DRAWABLE_FORMAT_RGBA8,
		bg
	)

	for node in root_node.children:
		node.root_texture_size = Vector2(width, height)
		node.instance_count_changed.connect(_on_node_instance_count_changed)
		node.material_parameters_changed.connect(_on_node_material_parameter_changed)
		instance_count += node.instance_count

	update()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESOURCE_DESERIALIZED:
			if initialized:
				return

			_initialize()
			RenderingServer.texture_set_path(texture, get_path())

		NOTIFICATION_PREDELETE:
			RenderingServer.free_rid(dummy_source)
			RenderingServer.free_rid(material)
			RenderingServer.free_rid(texture)


func add_shape(shape: TextureNodeShape.Shape) -> String:
	var new_node:= TextureNodeShape.create(shape)
	root_node.children.append(new_node)
	new_node.root_texture_size = Vector2(width, height)
	new_node.instance_count_changed.connect(_on_node_instance_count_changed)
	new_node.material_parameters_changed.connect(_on_node_material_parameter_changed)
	instance_count += new_node.instance_count
	update()
	return new_node._get_name()


func remove_node(index: int) -> void:
	instance_count -= root_node.children[index].instance_count
	root_node.children.remove_at(index)
	update()


func move_node(node: TextureNode, to_index: int) -> void:
	root_node.children.erase(node)
	root_node.children.insert(to_index, node)
	update()


func update() -> void:
	_set_instance_material_parameters()
	for param_name in ShapeMaterialParameters.array_parameter_names:
		_set_material_parameter(param_name)

	_redraw()


func _redraw() -> void:
	var bg:= Oklab.linear_to_oklab(background_color.srgb_to_linear())
	RenderingServer.texture_drawable_blit_rect(
		[texture],
		Rect2i(Vector2i.ZERO, Vector2i(width, height)),
		material,
		bg,
		[dummy_source]
	)

	RenderingServer.texture_drawable_generate_mipmaps(texture)
	emit_changed()


func _on_size_changed() -> void:
	if not initialized:
		return

	for node in root_node.children:
		node.root_texture_size = Vector2(width, height)

	var bg:= Oklab.linear_to_oklab(background_color.srgb_to_linear())
	var new_texture:= RenderingServer.texture_drawable_create(
		width,
		height,
		RenderingServer.TEXTURE_DRAWABLE_FORMAT_RGBA8,
		bg
	)

	RenderingServer.texture_replace(texture, new_texture)

	update()


func _on_node_material_parameter_changed(param_names: Array) -> void:
	if not initialized:
		return

	for param_name: StringName in param_names:
		_set_material_parameter(param_name)

	_redraw()


func _on_node_instance_count_changed(change: int) -> void:
	if not initialized:
		return

	instance_count += change
	_set_instance_material_parameters()

	_redraw()


func _set_instance_material_parameters() -> void:
	RenderingServer.material_set_param(material, "shape_count", instance_count)

	for param_name in ShapeMaterialParameters.instance_parameter_names:
		_set_material_parameter(param_name)


func _set_material_parameter(param_name: StringName) -> void:
	var param:= PackedByteArray()
	var param_size:= ShapeMaterialParameters.material_parameter_size_in_bytes_map[param_name]
	param.resize(param_size * instance_count)

	# Loop over the nodes in reverse order so that the instances are in sequential draw order.
	var node_index:= root_node.children.size() - 1
	var instance_index:= 0
	# If a node has both a fill and outline, they are split in 2 instances.
	var outline_instance:= false
	# Gradient and shape data are passed as slices.
	var slice_accums: Dictionary[StringName, int] = {}
	while(node_index >= 0 or outline_instance):
		if outline_instance:
			# Return to previous node.
			node_index += 1

		var node:= root_node.children[node_index] as TextureNodeShape

		if not node.fill_enabled and not node.outline_enabled:
			node_index -= 1
			node = root_node.children[node_index]

		node._set_parameter(param_name, param, instance_index, outline_instance, slice_accums)

		if not outline_instance:
			if node.fill_enabled and node.outline_enabled:
				outline_instance = true
		else:
			outline_instance = false

		node_index -= 1
		instance_index += 1

	var typed_param = ShapeMaterialParameters.convert_parameter_array(param_name, param)
	RenderingServer.material_set_param(material, param_name, typed_param)


func _reset_state() -> void:
	pass


func _get_height() -> int:
	return height


func _get_width() -> int:
	return width


func _get_format() -> Image.Format:
	return Image.Format.FORMAT_RGBA8


func _get_image() -> Image:
	return RenderingServer.texture_2d_get(texture)


func _get_rid() -> RID:
	return texture


func _draw(to_ci: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect(
		to_ci, Rect2(pos, Vector2(width, height)), texture, false, modulate, transpose)


func _draw_rect(to_ci: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect(
		to_ci, rect, texture, tile, modulate, transpose)


func _draw_rect_region(to_ci: RID, rect: Rect2, src_rect: Rect2,
		modulate: Color, transpose: bool, clip_uv: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect_region(
		to_ci, rect, texture, src_rect, modulate, transpose, clip_uv)
