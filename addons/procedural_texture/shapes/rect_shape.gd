@tool
class_name RectShape
extends TextureNodeShape

@export var rect:= Vector2(10, 10):
	set(value):
		rect = value
		material_parameters_changed.emit([&"shape_data"])


func _set_parameter(
	param_name: StringName,
	param: PackedByteArray,
	instance_index: int,
	splitting: bool,
	slice_accums: Dictionary[StringName, int]
) -> void:
	super(param_name, param, instance_index, splitting, slice_accums)
	match param_name:
		&"shape_data_start":
			var data_start: int = slice_accums.get_or_add(&"shape_data_count", 0)
			param.encode_s32(instance_index * 4, data_start)
			slice_accums[&"shape_data_count"] = data_start + 2

		&"shape_data_count":
			var data_count:= 2
			param.encode_s32(instance_index * 4, data_count)

		&"shape_data":
			var data_start: int = slice_accums.get_or_add(&"shape_data_count", 0)
			var uv_rect: Vector2 = rect / max(rect.x, rect.y) / 2
			param.encode_float(data_start * 4 + 0, uv_rect.x)
			param.encode_float(data_start * 4 + 4, uv_rect.y)
			slice_accums[&"shape_data_count"] = data_start + 2


func _get_shape() -> Shape:
	return Shape.RECTANGLE


func _get_shape_data() -> PackedFloat32Array:
	var uv_rect: Vector2 = rect / max(rect.x, rect.y) / 2
	var data:= PackedFloat32Array()
	data.resize(2)
	data[0] = uv_rect.x
	data[1] = uv_rect.y
	return data


func _get_name() -> String:
	return "Rectangle"


func _get_height() -> int:
	return ceil(max(rect.x, rect.y))


func _get_width() -> int:
	return ceil(max(rect.x, rect.y))
