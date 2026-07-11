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

const MAX_SHAPE_COUNT = 16;
const AVG_GRADIENT_STOPS = 4;

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
	var shape_data:= PackedVector4Array()
	shape_data.resize(MAX_SHAPE_COUNT)
	var outline_enabled:= PackedInt32Array()
	outline_enabled.resize(MAX_SHAPE_COUNT)
	var outline_width:= PackedFloat32Array()
	outline_width.resize(MAX_SHAPE_COUNT)
	var outline_color:= PackedVector4Array()
	outline_color.resize(MAX_SHAPE_COUNT)
	var outline_smoothstep:= PackedFloat32Array()
	outline_smoothstep.resize(MAX_SHAPE_COUNT)
	var fill_enabled:= PackedInt32Array()
	fill_enabled.resize(MAX_SHAPE_COUNT)
	var fill_mode:= PackedInt32Array()
	fill_mode.resize(MAX_SHAPE_COUNT)
	var fill_color:= PackedVector4Array()
	fill_color.resize(MAX_SHAPE_COUNT)
	var fill_gradient_first_stop:= PackedInt32Array()
	fill_gradient_first_stop.resize(MAX_SHAPE_COUNT)
	var fill_gradient_stop_count:= PackedInt32Array()
	fill_gradient_stop_count.resize(MAX_SHAPE_COUNT)
	var fill_gradient_colors:= PackedVector4Array()
	fill_gradient_colors.resize(MAX_SHAPE_COUNT * AVG_GRADIENT_STOPS)
	var fill_gradient_stops:= PackedFloat32Array()
	fill_gradient_stops.resize(MAX_SHAPE_COUNT * AVG_GRADIENT_STOPS)
	var linear_gradient_rotation:= PackedVector4Array()
	linear_gradient_rotation.resize(MAX_SHAPE_COUNT)
	var radial_gradient_origin:= PackedVector2Array()
	radial_gradient_origin.resize(MAX_SHAPE_COUNT)
	var radial_gradient_radius:= PackedFloat32Array()
	radial_gradient_radius.resize(MAX_SHAPE_COUNT)
	var fill_smoothstep:= PackedFloat32Array()
	fill_smoothstep.resize(MAX_SHAPE_COUNT)

	var count:= root_node.children.size()
	var stop_count_accum:= 0
	for i in range(count - 1, -1, -1):
		var node:= root_node.children[i] as TextureNodeShape
		var side_length:= node._get_width() as float
		shape[i] = node._get_shape()
		var size:= Vector2(node._get_width(), node._get_height())
		var rect:= Rect2(Vector2(node.position) - size / 2, size)
		var tex_size:= Vector2(width, height)
		rect = Rect2(rect.position / tex_size, rect.size / tex_size)
		shape_rect[i] = Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y)
		var r:= Transform2D.IDENTITY.rotated(node.rotation)
		shape_rotation[i] = Vector4(r.x.x, r.x.y, r.y.x, r.y.y)
		shape_data[i] = node._get_shape_data()
		outline_enabled[i] = node.outline_enabled as int
		outline_width[i] = node.outline_width / side_length
		outline_color[i] = get_oklab(node.outline_color)
		outline_smoothstep[i] = node.outline_smoothing_factor / side_length
		fill_enabled[i] = node.fill_enabled as int
		fill_mode[i] = node.fill_mode
		fill_color[i] = get_oklab(node.fill_color)
		var colors:= node.fill_gradient.get_colors()
		var stops:= node.fill_gradient.get_stops()
		var stop_count:= colors.size()
		fill_gradient_first_stop[i] = stop_count_accum
		fill_gradient_stop_count[i] = stop_count
		var j:= 0
		for k in range(stop_count_accum, stop_count_accum + stop_count):
			fill_gradient_colors[k] = colors[j]
			fill_gradient_stops[k] = stops[j]
			j += 1
		stop_count_accum += stop_count
		var rot:= Transform2D.IDENTITY.rotated(node.fill_linear_gradient_rotation)
		linear_gradient_rotation[i] = Vector4(rot.x.x, rot.x.y, rot.y.x, rot.y.y)
		radial_gradient_origin[i] = node.fill_radial_gradient_origin
		radial_gradient_radius[i] = node.fill_radial_gradient_radius
		fill_smoothstep[i] = node.fill_smoothing_factor / side_length

	RenderingServer.material_set_param(material, "shape_count", count)
	RenderingServer.material_set_param(material, "shape", shape)
	RenderingServer.material_set_param(material, "shape_rect", shape_rect)
	RenderingServer.material_set_param(material, "shape_rotation", shape_rotation)
	RenderingServer.material_set_param(material, "shape_data", shape_data)
	RenderingServer.material_set_param(material, "outline_enabled", outline_enabled)
	RenderingServer.material_set_param(material, "outline_width", outline_width)
	RenderingServer.material_set_param(material, "outline_color", outline_color)
	RenderingServer.material_set_param(material, "outline_smoothstep", outline_smoothstep)
	RenderingServer.material_set_param(material, "fill_enabled", fill_enabled)
	RenderingServer.material_set_param(material, "fill_mode", fill_mode)
	RenderingServer.material_set_param(material, "fill_color", fill_color)
	RenderingServer.material_set_param(material, "fill_gradient_first_stop", fill_gradient_first_stop)
	RenderingServer.material_set_param(material, "fill_gradient_stop_count", fill_gradient_stop_count)
	RenderingServer.material_set_param(material, "fill_gradient_colors", fill_gradient_colors)
	RenderingServer.material_set_param(material, "fill_gradient_stops", fill_gradient_stops)
	RenderingServer.material_set_param(material, "linear_gradient_rotation", linear_gradient_rotation)
	RenderingServer.material_set_param(material, "radial_gradient_origin", radial_gradient_origin)
	RenderingServer.material_set_param(material, "radial_gradient_radius", radial_gradient_radius)
	RenderingServer.material_set_param(material, "fill_smoothstep", fill_smoothstep)


func get_oklab(color: Color) -> Vector4:
	var oklab:= Oklch.linear_to_oklab(color.srgb_to_linear())
	return Vector4(oklab.l, oklab.a, oklab.b, oklab.alpha)
