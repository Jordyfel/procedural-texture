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
		emit_changed()

@export_storage var root_node: TextureNode
@export_storage var shader: Shader

const MAX_SHAPE_COUNT = 16
const AVG_GRADIENT_STOPS = 4
const AVG_SHAPE_DATA = 16

var initialized:= false

var texture: RID
var material: RID
var dummy_source: RID

func _init() -> void:
	var image:= Image.create_empty(2, 2, false, Image.Format.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	dummy_source = RenderingServer.texture_2d_create(image)
	texture = dummy_source
	material = RenderingServer.material_create()



func setup() -> void:
	root_node = TextureNode.new()
	_initialize()


func _initialize() -> void:
	initialized = true
	shader = load("res://addons/procedural_texture/shape.gdshader")
	RenderingServer.material_set_shader(material, shader.get_rid())
	var bg:= get_oklab(background_color)
	texture = RenderingServer.texture_drawable_create(
		width,
		height,
		RenderingServer.TEXTURE_DRAWABLE_FORMAT_RGBA8,
		Color(bg.x, bg.y, bg.z, bg.w)
	)

	changed.connect(update)
	for node in root_node.children:
		node.changed.connect(update)

	update()


func _on_size_changed() -> void:
	if root_node == null or not root_node.texture.is_valid():
		return

	var bg:= get_oklab(background_color)
	var new_texture:= RenderingServer.texture_drawable_create(
		width,
		height,
		RenderingServer.TEXTURE_DRAWABLE_FORMAT_RGBA8,
		Color(bg.x, bg.y, bg.z, bg.w)
	)

	RenderingServer.texture_replace(texture, new_texture)

	emit_changed()


func update() -> void:
	_set_material_parameters()
	var bg:= get_oklab(background_color)
	RenderingServer.texture_drawable_blit_rect(
		[texture],
		Rect2i(Vector2i.ZERO, Vector2i(width, height)),
		material,
		Color(bg.x, bg.y, bg.z, bg.w),
		[dummy_source]
	)

	RenderingServer.texture_drawable_generate_mipmaps(texture)


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


func _set_material_parameters() -> void:
	var shape:= PackedInt32Array()
	shape.resize(MAX_SHAPE_COUNT)
	var shape_rect:= PackedVector4Array()
	shape_rect.resize(MAX_SHAPE_COUNT)
	var shape_rotation:= PackedVector4Array()
	shape_rotation.resize(MAX_SHAPE_COUNT)
	var shape_data_start:= PackedInt32Array()
	shape_data_start.resize(MAX_SHAPE_COUNT)
	var shape_data_count:= PackedInt32Array()
	shape_data_count.resize(MAX_SHAPE_COUNT)
	var shape_data:= PackedFloat32Array()
	shape_data.resize(MAX_SHAPE_COUNT * AVG_SHAPE_DATA)
	var shape_draw_mode:= PackedInt32Array()
	shape_draw_mode.resize(MAX_SHAPE_COUNT)
	var shape_outline_width:= PackedFloat32Array()
	shape_outline_width.resize(MAX_SHAPE_COUNT)
	var shape_color:= PackedVector4Array()
	shape_color.resize(MAX_SHAPE_COUNT)
	var shape_smoothing:= PackedFloat32Array()
	shape_smoothing.resize(MAX_SHAPE_COUNT)
	var gradient_first_stop:= PackedInt32Array()
	gradient_first_stop.resize(MAX_SHAPE_COUNT)
	var gradient_stop_count:= PackedInt32Array()
	gradient_stop_count.resize(MAX_SHAPE_COUNT)
	var gradient_colors:= PackedVector4Array()
	gradient_colors.resize(MAX_SHAPE_COUNT * AVG_GRADIENT_STOPS)
	var gradient_stops:= PackedFloat32Array()
	gradient_stops.resize(MAX_SHAPE_COUNT * AVG_GRADIENT_STOPS)
	var gradient_stop_origins:= PackedVector2Array()
	gradient_stop_origins.resize(MAX_SHAPE_COUNT * AVG_GRADIENT_STOPS)
	var gradient_transform_data:= PackedVector4Array()
	gradient_transform_data.resize(MAX_SHAPE_COUNT)

	# Loop over the nodes in reverse order so that the instances are in sequential draw order.
	# Node index.
	var n:= root_node.children.size() - 1
	# Instance index.
	var i:= 0
	# If a node has both a fill and outline, they are split in 2 instances.
	var repeating:= false
	# Gradient and shape data are passed as slices.
	var stop_count_accum:= 0
	var shape_data_count_accum:= 0
	while(n >= 0 or repeating):
		if repeating:
			# Return to previous node.
			n += 1

		var node:= root_node.children[n] as TextureNodeShape

		# Outline is above so always true when repeating.
		var is_outline:= true
		if not repeating:
			if node.fill_enabled:
				is_outline = false
				if node.outline_enabled:
					# If both are enabled, repeat.
					repeating = true
			elif not node.outline_enabled:
				# If neither are enabled, skip the node.
				n -= 1
				continue

		shape[i] = node._get_shape()
		var side_length:= node._get_width() as float
		var size:= Vector2(node._get_width(), node._get_height())
		if repeating:
			if not is_outline:
				# If there will be an outline over this fill, reduce size.
				var mult:= 1 - (node.outline_width / side_length / 2)
				size *= Vector2(mult, mult)
			else:
				# We are done with this state, reset.
				repeating = false

		var rect:= Rect2(Vector2(node.position) - size / 2, size)
		var tex_size:= Vector2(width, height)
		rect = Rect2(rect.position / tex_size, rect.size / tex_size)
		shape_rect[i] = Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y)

		var r:= Transform2D.IDENTITY.rotated(node.rotation)
		shape_rotation[i] = Vector4(r.x.x, r.x.y, r.y.x, r.y.y)

		var data_source:= node._get_shape_data()
		var data_count:= data_source.size()
		shape_data_start[i] = shape_data_count_accum
		shape_data_count[i] = data_count
		var data_source_index:= 0
		for data_index in range(shape_data_count_accum, shape_data_count_accum + data_count):
			shape_data[data_index] = data_source[data_source_index]
			data_source_index += 1
		shape_data_count_accum += data_count

		shape_draw_mode[i] = 5 if is_outline else node.fill_mode # TODO: Rework outline mode data.
		shape_outline_width[i] = node.outline_width / side_length
		shape_color[i] = get_oklab(node.outline_color) if is_outline else get_oklab(node.fill_color)
		var smoothing:= node.outline_smoothing if is_outline else node.fill_smoothing
		shape_smoothing[i] = smoothing / side_length

		var colors:= node.gradient.get_colors()
		var stops:= node.gradient.get_stops()
		var stop_origins:= node.gradient.get_stop_origins()
		var stop_count:= colors.size()
		gradient_first_stop[i] = stop_count_accum
		gradient_stop_count[i] = stop_count
		var stop_source_index:= 0
		for stop_index in range(stop_count_accum, stop_count_accum + stop_count):
			gradient_colors[stop_index] = colors[stop_source_index]
			gradient_stops[stop_index] = stops[stop_source_index]
			gradient_stop_origins[stop_index] = stop_origins[stop_source_index]
			stop_source_index += 1
		stop_count_accum += stop_count

		var rot:= Transform2D.IDENTITY.rotated(node.linear_gradient_rotation)
		match node.fill_mode:
			TextureNodeShape.FillMode.LINEAR_GRADIENT:
				gradient_transform_data[i] = Vector4(rot.x.x, rot.x.y, rot.y.x, rot.y.y)
			TextureNodeShape.FillMode.RADIAL_GRADIENT:
				gradient_transform_data[i].x = node.radial_gradient_origin.x
				gradient_transform_data[i].y = node.radial_gradient_origin.y
				gradient_transform_data[i].z = node.radial_gradient_radius

		n -= 1
		i += 1

	RenderingServer.material_set_param(material, "shape_count", i)
	RenderingServer.material_set_param(material, "shape", shape)
	RenderingServer.material_set_param(material, "shape_rect", shape_rect)
	RenderingServer.material_set_param(material, "shape_rotation", shape_rotation)
	RenderingServer.material_set_param(material, "shape_data_start", shape_data_start)
	RenderingServer.material_set_param(material, "shape_data_count", shape_data_count)
	RenderingServer.material_set_param(material, "shape_data", shape_data)
	RenderingServer.material_set_param(material, "shape_draw_mode", shape_draw_mode)
	RenderingServer.material_set_param(material, "shape_outline_width", shape_outline_width)
	RenderingServer.material_set_param(material, "shape_color", shape_color)
	RenderingServer.material_set_param(material, "shape_smoothing", shape_smoothing)
	RenderingServer.material_set_param(material, "gradient_first_stop", gradient_first_stop)
	RenderingServer.material_set_param(material, "gradient_stop_count", gradient_stop_count)
	RenderingServer.material_set_param(material, "gradient_colors", gradient_colors)
	RenderingServer.material_set_param(material, "gradient_stops", gradient_stops)
	RenderingServer.material_set_param(material, "gradient_stop_origins", gradient_stop_origins)
	RenderingServer.material_set_param(material, "gradient_transform_data", gradient_transform_data)


func get_oklab(color: Color) -> Vector4:
	var oklab:= Oklch.linear_to_oklab(color.srgb_to_linear())
	return Vector4(oklab.l, oklab.a, oklab.b, oklab.alpha)
