@tool
class_name CircleShape
extends TextureNodeShape

@export_range(0, 512, 0.01, "or_greater", "prefer_slider") var radius:= 10.0:
	set(value):
		radius = value
		emit_changed()


func _get_shape() -> Shape:
	return Shape.CIRCLE


func _get_name() -> String:
	return "Circle"


func _get_height() -> int:
	return ceil(radius * 2)


func _get_width() -> int:
	return ceil(radius * 2)
