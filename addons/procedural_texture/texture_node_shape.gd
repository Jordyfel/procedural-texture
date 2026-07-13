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


@export_group("Fill", "fill")
@export_custom(PROPERTY_HINT_GROUP_ENABLE,"") var fill_enabled:= true:
	set(value):
		fill_enabled = value
		material_parameters_changed.emit([&"instance"])

@export var fill_mode:= FillMode.SOLID_COLOR:
	set(value):
		fill_mode = value
		material_parameters_changed.emit([&"shape_draw_mode", &"draw_mode_data"])

@export var fill_color:= Color.WHITE:
	set(value):
		fill_color = value
		material_parameters_changed.emit([&"shape_color"])

@export_range(0, 10, 0.01, "or_greater", "prefer_slider") var smoothing:= 2.8:
	set(value):
		smoothing = value
		material_parameters_changed.emit([&"shape_smoothing"])

@export var gradient:= OklabGradient.new()

@export_range(0, 360, 0.001, "radians_as_degrees") var linear_gradient_rotation:= 0.0:
	set(value):
		linear_gradient_rotation = value
		material_parameters_changed.emit([&"draw_mode_data"])

@export var radial_gradient_origin:= Vector2(0.5, 0.5):
	set(value):
		radial_gradient_origin = value
		material_parameters_changed.emit([&"draw_mode_data"])

@export_range(0, 1.0, 0.001, "or_greater", "prefer_slider") var radial_gradient_radius:= 0.5:
	set(value):
		radial_gradient_radius = value
		material_parameters_changed.emit([&"draw_mode_data"])


static func create(shape: Shape) -> TextureNodeShape:
	var new_shape: TextureNodeShape
	match shape:
		Shape.CIRCLE:
			new_shape = CircleShape.new()
		Shape.RECTANGLE:
			new_shape = RectShape.new()
		_:
			new_shape = CircleShape.new()

	assert(
		new_shape.fill_enabled or new_shape.outline_enabled,
		"Newly created shapes being disabled breaks assumptions in shader data update logic."
	)

	return new_shape


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
			var color := outline_color if is_outline else fill_color
			color = Oklab.linear_to_oklab(color.srgb_to_linear())
			param.encode_float(instance_index * 16 + 0, color.r)
			param.encode_float(instance_index * 16 + 4, color.g)
			param.encode_float(instance_index * 16 + 8, color.b)
			param.encode_float(instance_index * 16 + 12, color.a)

		&"shape_smoothing":
			param.encode_float(instance_index * 4, smoothing / _get_width() as float)

		&"draw_mode_data":
			var draw_mode_data:= Vector3()
			match fill_mode:
				FillMode.LINEAR_GRADIENT:
					draw_mode_data.x = linear_gradient_rotation
				FillMode.RADIAL_GRADIENT:
					draw_mode_data.x = radial_gradient_origin.x
					draw_mode_data.y = radial_gradient_origin.y
					draw_mode_data.z = radial_gradient_radius

			param.encode_float(instance_index * 12 + 0, draw_mode_data.x)
			param.encode_float(instance_index * 12 + 4, draw_mode_data.y)
			param.encode_float(instance_index * 12 + 8, draw_mode_data.z)

		&"gradient_first_stop":
			var stop_count:= gradient.stops.size()
			# If outline instance, record a slice to previous instances data.
			var offset:= 0 if not outline_instance else -stop_count
			var first_stop: int = slice_accums.get_or_add(&"stop_count", 0)
			param.encode_s32(instance_index * 4, first_stop + offset)
			slice_accums[&"stop_count"] = first_stop + offset + gradient.stops.size()

		&"gradient_stop_count":
			var stop_count:= gradient.stops.size()
			param.encode_s32(instance_index * 4, stop_count)

		&"gradient_colors":
			if outline_instance:
				return

			var first_stop: int = slice_accums.get_or_add(&"stop_count", 0)
			var colors:= gradient.get_colors()
			for i in colors.size():
				param.encode_float(first_stop * 16 + i * 4, colors[i])
			@warning_ignore("integer_division")
			slice_accums[&"stop_count"] = first_stop + colors.size() / 4

		&"gradient_stops":
			if outline_instance:
				return

			var first_stop: int = slice_accums.get_or_add(&"stop_count", 0)
			var stops:= gradient.get_stops()
			for i in stops.size():
				param.encode_float(first_stop * 4 + i * 4, stops[i])
			slice_accums[&"stop_count"] = first_stop + stops.size()

		&"gradient_stop_origins":
			if outline_instance:
				return

			var first_stop: int = slice_accums.get_or_add(&"stop_count", 0)
			var stop_origins:= gradient.get_stop_origins()
			for i in stop_origins.size():
				param.encode_float(first_stop * 8 + i * 4, stop_origins[i])
			@warning_ignore("integer_division")
			slice_accums[&"stop_count"] = first_stop + stop_origins.size() / 2


func _get_shape() -> Shape:
	return Shape.CIRCLE
