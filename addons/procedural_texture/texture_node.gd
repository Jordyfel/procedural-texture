@tool
class_name TextureNode
extends Resource

signal instance_count_changed(change: int)
signal material_parameters_changed(param_names: Array)

@export var position: Vector2:
	set(value):
		position = value
		material_parameters_changed.emit([&"shape_rect"])

@export_range(0, 360, 0.001, "radians_as_degrees") var rotation: float:
	set(value):
		rotation = value
		material_parameters_changed.emit([&"shape_rotation"])

@export_storage var children: Array[TextureNode]

var texture_size: Vector2

var instance_count:= 0


func _set_parameter(
	param_name: StringName,
	param: PackedByteArray,
	instance_index: int,
	_second_instance: bool,
	_slice_accums: Dictionary[StringName, int]
) -> void:
	match param_name:
		&"shape_rotation":
			param.encode_float(instance_index * 4, rotation)


func _get_name() -> String:
	return ""


func _get_side_length() -> int:
	return 256
