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


func setup() -> void:
	var name = _get_name()
	if name.is_empty(): # Is root.
		return

	const SHAPE_PATH = "res://addons/procedural_texture/shapes/"
	shader = load(SHAPE_PATH + name.to_lower() + ".gdshader")

	_initialize()


func _initialize() -> void:
	material = RenderingServer.material_create()
	RenderingServer.material_set_shader(material, shader.get_rid())


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESOURCE_DESERIALIZED:
		if _get_name().is_empty() or material.is_valid(): # Is root or is initialized.
			return

		_initialize()

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
