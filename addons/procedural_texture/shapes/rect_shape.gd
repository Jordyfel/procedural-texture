@tool
class_name RectShape
extends TextureNodeShape

@export var rect: Vector2:
	set(value):
		rect = value
		emit_changed()

func _set_material_parameters() -> void:
	super()
	RenderingServer.material_set_param(material, "rect", rect)


func _get_name() -> String:
	return "Rectangle"


func _get_height() -> int:
	return ceil(max(rect.x, rect.y))


func _get_width() -> int:
	return ceil(max(rect.x, rect.y))
