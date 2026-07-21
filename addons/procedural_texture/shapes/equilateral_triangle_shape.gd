@tool
class_name EquilateralTriangleShape
extends TextureNodeShape

@export_range(0, 512, 0.01, "or_greater", "prefer_slider") var radius:= 20.0:
	set(value):
		radius = value
		material_parameters_changed.emit([&"shape_rect"])


func _get_shape() -> Shape:
	return Shape.EQUILATERAL_TRIANGLE


func _get_name() -> String:
	return "Equilateral Triangle"


func _get_side_length() -> int:
	return ceil(radius * 2)
