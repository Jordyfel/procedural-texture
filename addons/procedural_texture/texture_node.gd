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

@export_storage var shader: Shader
@export_storage var children: Array[TextureNode]

var material: RID
var texture: RID


func _init() -> void:
	shader = _get_shader()
	if shader == null: # Is root.
		return

	material = RenderingServer.material_create()
	RenderingServer.material_set_shader(material, shader.get_rid())


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and material.is_valid():
		RenderingServer.free_rid(material)


func _set_material_parameters() -> void:
	pass


func _get_name() -> String:
	return ""


func _get_height() -> int:
	return 256


func _get_width() -> int:
	return 256


func _get_shader() -> Shader:
	return null
