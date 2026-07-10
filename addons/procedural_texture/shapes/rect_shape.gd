@tool
class_name RectShape
extends TextureNodeShape

@export var rect:= Vector2(10, 10):
	set(value):
		rect = value
		emit_changed()


func _set_material_parameters() -> void:
	super()
	RenderingServer.material_set_param(material, "shape", Shape.RECTANGLE)
	var uv_rect: Vector2 = rect / max(rect.x, rect.y) / 2
	var shape_data:= Vector4(uv_rect.x, uv_rect.y, 0, 0)
	RenderingServer.material_set_param(material, "shape_data", shape_data)


func _get_name() -> String:
	return "Rectangle"


func _get_height() -> int:
	return ceil(max(rect.x, rect.y))


func _get_width() -> int:
	return ceil(max(rect.x, rect.y))
