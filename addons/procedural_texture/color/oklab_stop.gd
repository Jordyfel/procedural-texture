@tool
class_name OklabStop
extends Resource

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY)
var color: Color

@export_range(0.0, 1.0, 0.001, "prefer_slider") var l: float:
	set(value):
		l = value
		color = oklch_to_srgb()

@export_range(0.0, 0.4, 0.001, "prefer_slider") var c: float:
	set(value):
		c = value
		color = oklch_to_srgb()

@export_range(0.0, 360.0, 0.1, "prefer_slider") var h: float:
	set(value):
		h = value
		color = oklch_to_srgb()

@export_range(0.0, 1.0, 0.001, "prefer_slider") var a: float:
	set(value):
		a = value
		color = oklch_to_srgb()


@export_range(0.0, 1.0, 0.001, "prefer_slider") var stop: float

## Used in 2D gradients. TODO: Implement, and add weights property to encode into stops.
@export var stop_origin: Vector2


func oklch_to_srgb() -> Color:
	var oklch:= Color(l, c, h, a)
	return Oklab.oklab_to_linear(Oklab.oklch_to_oklab(oklch)).linear_to_srgb()
