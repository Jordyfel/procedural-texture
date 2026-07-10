@tool
class_name TextureNode
extends Resource

@export var position: Vector2:
	set(value):
		position = value
		emit_changed()

@export_range(0, 360, 0.001, "radians_as_degrees") var rotation: float:
	set(value):
		rotation = value
		emit_changed()

@export_storage var children: Array[TextureNode]


func _get_name() -> String:
	return ""


func _get_height() -> int:
	return 256


func _get_width() -> int:
	return 256


func _get_shader() -> Shader:
	return null
