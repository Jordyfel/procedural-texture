@tool
class_name TextureNode
extends Resource

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

var root_texture_size: Vector2


func _set_parameter(
	param_name: StringName,
	param: PackedByteArray,
	instance_index: int,
	_outline_instance: bool,
	_slice_accums: Dictionary[StringName, int]
) -> void:
	match param_name:
		&"shape_rotation":
			var r:= Transform2D.IDENTITY.rotated(rotation)
			param.encode_float(instance_index * 16 + 0, r.x.x)
			param.encode_float(instance_index * 16 + 4, r.x.y)
			param.encode_float(instance_index * 16 + 8, r.y.x)
			param.encode_float(instance_index * 16 + 12, r.y.y)


func _get_name() -> String:
	return ""


func _get_height() -> int:
	return 256


func _get_width() -> int:
	return 256


func _get_shader() -> Shader:
	return null
