@tool
class_name TriangleShape
extends TextureNodeShape

@export var point_1:= Vector2(0, 0):
	set(value):
		point_1 = value
		material_parameters_changed.emit([&"shape_rect", &"shape_data"])

@export var point_2:= Vector2(20, 0):
	set(value):
		point_2 = value
		material_parameters_changed.emit([&"shape_rect", &"shape_data"])

@export var point_3:= Vector2(10, 10):
	set(value):
		point_3 = value
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
			param.encode_float(data_start * 4 + 0, point_1.x / side_length - 0.5)
			param.encode_float(data_start * 4 + 4, point_1.y / side_length)
			param.encode_float(data_start * 4 + 8, point_2.x / side_length - 0.5)
			param.encode_float(data_start * 4 + 12, point_2.y / side_length)
			param.encode_float(data_start * 4 + 16, point_3.x / side_length - 0.5)
			param.encode_float(data_start * 4 + 20, point_3.y / side_length)
			slice_accums[&"shape_data_count"] = data_start + _get_shape_data_float_count()


func _get_shape() -> Shape:
	return Shape.TRIANGLE


func _get_name() -> String:
	return "Triangle"


func _get_side_length() -> int:
	#var pos:= point_1.min(point_2.min(point_3))
	var end:= point_1.max(point_2.max(point_3))
	print(max(end.x, end.y))
	return max(end.x, end.y)


func _get_shape_data_float_count() -> int:
	return 6
