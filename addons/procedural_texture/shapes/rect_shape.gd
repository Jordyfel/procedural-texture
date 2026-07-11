@tool
class_name RectShape
extends TextureNodeShape

@export var rect:= Vector2(10, 10):
	set(value):
		rect = value
		emit_changed()


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
