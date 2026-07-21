@tool
class_name ParallelogramShape
extends TextureNodeShape

@export_range(0, 100, 0.01, "or_greater", "prefer_slider") var width:= 20.0:
	set(value):
		width = value
		material_parameters_changed.emit([&"shape_rect", &"shape_data"])

@export_range(0, 100, 0.01, "or_greater", "prefer_slider") var height:= 20.0:
	set(value):
		height = value
		material_parameters_changed.emit([&"shape_rect", &"shape_data"])

@export_range(-0.5, 0.5, 0.001, "or_greater", "prefer_slider") var skew:= 0.25:
	set(value):
		skew = value
		material_parameters_changed.emit([&"shape_rect", &"shape_data"])


func _set_parameter(
	param_name: StringName,
	param: PackedByteArray,
	instance_index: int,
	second_instance: bool,
	texture_size: Vector2,
	slice_accums: Dictionary[StringName, int]
) -> void:
	super(param_name, param, instance_index, second_instance, texture_size, slice_accums)
	match param_name:
		&"shape_data":
			if second_instance:
				return

			var data_start: int = slice_accums.get_or_add(&"shape_data_count", 0)
			var side_length:= _get_side_length() as float
			param.encode_float(data_start * 4 + 0, width / 2 / side_length)
			param.encode_float(data_start * 4 + 4, height / 2 / side_length)
			param.encode_float(data_start * 4 + 8, skew * (height / side_length))
			slice_accums[&"shape_data_count"] = data_start + _get_shape_data_float_count()


func _get_shape() -> Shape:
	return Shape.PARALLELOGRAM


func _get_name() -> String:
	return "Parallelogram"


func _get_side_length() -> int:
	return ceil(max(height, width + height * abs(skew * 2)))


func _get_shape_data_float_count() -> int:
	return 3
