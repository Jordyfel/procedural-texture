@tool
class_name ProceduralTexture
extends Texture2D

@export_storage var height:= 1
@export_storage var width:= 1
@export_storage var color:= Color.WHITE

@export_storage var root_node: TextureNode

var root_texture: RID
var default_material: RID
var dummy_source: RID


func _init() -> void:
	var image:= Image.create_empty(2, 2, false, Image.Format.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	dummy_source = RenderingServer.texture_2d_create(image)
	default_material = RenderingServer.texture_drawable_get_default_material()
	root_texture = dummy_source


func setup() -> void:
	root_node = TextureNode.new()
	_initialize()


func _initialize() -> void:
	root_texture = RenderingServer.texture_drawable_create(
		width,
		height,
		RenderingServer.TEXTURE_DRAWABLE_FORMAT_RGBA8,
		color
	)

	root_node.texture = root_texture

	for node in root_node.children:
		node.changed.connect(update)

	update()


func update() -> void:
	# Clear the main texture.
	RenderingServer.texture_drawable_blit_rect(
		[root_node.texture],
		Rect2i(Vector2i.ZERO, Vector2i(width, height)),
		default_material,
		color,
		[dummy_source]
	)

	# Create intermediate textures.
	for node in root_node.children:
		if node.children.is_empty():
			# Only draws on parent, nothing is drawn on it.
			continue

		# FIXME: Completely untested.
		node.texture = RenderingServer.texture_drawable_create(
			_get_width(),
			_get_height(),
			RenderingServer.TEXTURE_DRAWABLE_FORMAT_RGBA8,
			Color.WHITE
		)

	# Blit in reverse order.
	for i in range(root_node.children.size() - 1, -1, -1):
		var node = root_node.children[i]
		node._set_material_parameters()
		var size:= Vector2i(node._get_width(), node._get_height())
		@warning_ignore("integer_division")
		var rect:= Rect2i(Vector2i(node.position.round()) - size / 2, size)
		RenderingServer.texture_drawable_blit_rect(
			[root_node.texture],
			rect,
			node.material,
			Color.WHITE,
			[node.texture]
		)

	RenderingServer.texture_drawable_generate_mipmaps(root_texture)

	# Free intermediate textures.
	for node in root_node.children:
		if node.children.is_empty():
			continue

		# FIXME: Completely untested.
		RenderingServer.free_rid(node.texture)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESOURCE_DESERIALIZED:
			if root_node.texture.is_valid():
				return

			_initialize()
			RenderingServer.texture_set_path(root_texture, get_path())

		NOTIFICATION_PREDELETE:
			RenderingServer.free_rid(dummy_source)
			RenderingServer.free_rid(default_material)
			RenderingServer.free_rid(root_texture)


func _reset_state() -> void:
	pass


func _get_height() -> int:
	return height


func _get_width() -> int:
	return width


func _get_format() -> Image.Format:
	return Image.Format.FORMAT_RGBA8


func _get_image() -> Image:
	return RenderingServer.texture_2d_get(root_texture)


func _get_rid() -> RID:
	return root_texture


func _draw(to_ci: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect(
		to_ci, Rect2(pos, Vector2(width, height)), root_texture, false, modulate, transpose)


func _draw_rect(to_ci: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect(
		to_ci, rect, root_texture, tile, modulate, transpose)


func _draw_rect_region(to_ci: RID, rect: Rect2, src_rect: Rect2,
		modulate: Color, transpose: bool, clip_uv: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect_region(
		to_ci, rect, root_texture, src_rect, modulate, transpose, clip_uv)
