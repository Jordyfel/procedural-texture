@tool
@abstract class_name TextureNodeShape
extends TextureNode

enum Shape {CIRCLE, RECTANGLE}

# Keep in sync with constants in shape.gdshaderinc.
enum FillMode {SOLID_COLOR, DISTANCE_GRADIENT, LINEAR_GRADIENT, RADIAL_GRADIENT, GRADIENT_2D}

@export_group("Outline", "outline")
@export_custom(PROPERTY_HINT_GROUP_ENABLE,"") var outline_enabled:= false:
	set(value):
		outline_enabled = value
		material_parameters_changed.emit([&"instance"])

@export_range(0, 20, 0.01, "or_greater", "prefer_slider") var outline_width:= 2.0:
	set(value):
		outline_width = value
		material_parameters_changed.emit([&"shape_outline_width"])

@export var outline_color:= Color.BLACK:
	set(value):
		outline_color = value
		material_parameters_changed.emit([&"shape_color"])

@export_range(0, 10, 0.01, "or_greater", "prefer_slider") var outline_smoothing:= 4.0:
	set(value):
		outline_smoothing = value
		material_parameters_changed.emit([&"shape_smoothing"])


@export_group("Fill", "fill")
@export_custom(PROPERTY_HINT_GROUP_ENABLE,"") var fill_enabled:= false:
	set(value):
		fill_enabled = value
		material_parameters_changed.emit([&"instance"])

@export var fill_mode:= FillMode.SOLID_COLOR:
	set(value):
		fill_mode = value
		material_parameters_changed.emit([&"shape_draw_mode", &"gradient_transform_data"])

@export var fill_color:= Color.WHITE:
	set(value):
		fill_color = value
		material_parameters_changed.emit([&"shape_color"])

@export_range(0, 10, 0.01, "or_greater", "prefer_slider") var fill_smoothing:= 4.0:
	set(value):
		fill_smoothing = value
		material_parameters_changed.emit([&"shape_smoothing"])

@export var gradient:= OklchGradient.new()

@export_range(0, 360, 0.001, "radians_as_degrees") var linear_gradient_rotation:= 0.0:
	set(value):
		linear_gradient_rotation = value
		material_parameters_changed.emit([&"gradient_transform_data"])

@export var radial_gradient_origin:= Vector2(0.5, 0.5):
	set(value):
		radial_gradient_origin = value
		material_parameters_changed.emit([&"gradient_transform_data"])

@export_range(0, 1.0, 0.001, "or_greater", "prefer_slider") var radial_gradient_radius:= 0.5:
	set(value):
		radial_gradient_radius = value
		material_parameters_changed.emit([&"gradient_transform_data"])


static func create(shape: Shape) -> TextureNodeShape:
	match shape:
		Shape.CIRCLE:
			return CircleShape.new()
		Shape.RECTANGLE:
			return RectShape.new()
		_:
			return CircleShape.new()


func _set_parameter(
	param_name: StringName,
	param: PackedByteArray,
	instance_index: int,
	outline_instance: bool,
	slice_accums: Dictionary[StringName, int]
) -> void:
	super(param_name, param, instance_index, outline_instance, slice_accums)
	match param_name:
		&"shape":
			var shape:= _get_shape() as int
			param.encode_s32(instance_index * 4, shape)

		&"shape_rect":
			var size:= Vector2(_get_width(), _get_height())
			if fill_enabled and outline_enabled and not outline_instance:
				# If there will be an outline over this fill, reduce size.
				var mult:= 1 - (outline_width / _get_width() as float / 2)
				size *= Vector2(mult, mult)

			var rect:= Rect2(Vector2(position) - size / 2, size)
			rect = Rect2(rect.position / root_texture_size, rect.size / root_texture_size)

			param.encode_float(instance_index * 16 + 0, rect.position.x)
			param.encode_float(instance_index * 16 + 4, rect.position.y)
			param.encode_float(instance_index * 16 + 8, rect.size.x)
			param.encode_float(instance_index * 16 + 12, rect.size.y)

		&"shape_draw_mode":
			var is_outline:= not fill_enabled or outline_instance
			var draw_mode:= 5 if is_outline else fill_mode # TODO: Rework outline mode data.
			param.encode_s32(instance_index * 4, draw_mode)

		&"shape_outline_width":
			var width:= outline_width / _get_width() as float
			param.encode_float(instance_index * 4, width)

		&"shape_color":
			var is_outline:= not fill_enabled or outline_instance
			var color := get_oklab(outline_color) if is_outline else get_oklab(fill_color)
			param.encode_float(instance_index * 16 + 0, color.x)
			param.encode_float(instance_index * 16 + 4, color.y)
			param.encode_float(instance_index * 16 + 8, color.z)
			param.encode_float(instance_index * 16 + 12, color.w)

		&"shape_smoothing":
			var is_outline:= not fill_enabled or outline_instance
			var smoothing:= outline_smoothing if is_outline else fill_smoothing
			smoothing /= _get_width() as float
			param.encode_float(instance_index * 4, smoothing)

		&"gradient_first_stop":
			var first_stop: int = slice_accums.get_or_add(&"stop_count", 0)
			param.encode_s32(instance_index * 4, first_stop)
			slice_accums[&"stop_count"] = first_stop + gradient.stops.size()

		&"gradient_stop_count":
			var stop_count:= gradient.stops.size()
			param.encode_s32(instance_index * 4, stop_count)

		&"gradient_colors":
			var first_stop: int = slice_accums.get_or_add(&"stop_count", 0)
			var colors:= gradient.get_colors()
			for i in colors.size():
				param.encode_float(first_stop * 16 + i * 4, colors[i])
			@warning_ignore("integer_division")
			slice_accums[&"stop_count"] = first_stop + colors.size() / 4

		&"gradient_stops":
			var first_stop: int = slice_accums.get_or_add(&"stop_count", 0)
			var stops:= gradient.get_stops()
			for i in stops.size():
				param.encode_float(first_stop * 4 + i * 4, stops[i])
			slice_accums[&"stop_count"] = first_stop + stops.size()

		&"gradient_stop_origins":
			var first_stop: int = slice_accums.get_or_add(&"stop_count", 0)
			var stop_origins:= gradient.get_stop_origins()
			for i in stop_origins.size():
				param.encode_float(first_stop * 8 + i * 4, stop_origins[i])
			@warning_ignore("integer_division")
			slice_accums[&"stop_count"] = first_stop + stop_origins.size() / 2

		&"gradient_transform_data":
			var gradient_transform_data:= Vector4()
			match fill_mode:
				FillMode.LINEAR_GRADIENT:
					var rot:= Transform2D.IDENTITY.rotated(linear_gradient_rotation)
					gradient_transform_data = Vector4(rot.x.x, rot.x.y, rot.y.x, rot.y.y)
				FillMode.RADIAL_GRADIENT:
					gradient_transform_data.x = radial_gradient_origin.x
					gradient_transform_data.y = radial_gradient_origin.y
					gradient_transform_data.z = radial_gradient_radius

			param.encode_float(instance_index * 16 + 0, gradient_transform_data.x)
			param.encode_float(instance_index * 16 + 4, gradient_transform_data.y)
			param.encode_float(instance_index * 16 + 8, gradient_transform_data.z)
			param.encode_float(instance_index * 16 + 12, gradient_transform_data.w)


func get_oklab(color: Color) -> Vector4:
	var oklab:= Oklch.linear_to_oklab(color.srgb_to_linear())
	return Vector4(oklab.l, oklab.a, oklab.b, oklab.alpha)


func _get_shape() -> Shape:
	return Shape.CIRCLE


func _get_shape_data() -> PackedFloat32Array:
	return PackedFloat32Array()
