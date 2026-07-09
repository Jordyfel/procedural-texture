@tool
class_name OklchStop
extends Resource

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY)
var color: Color

@export_range(0.0, 1.0, 0.001, "prefer_slider") var l: float
@export_range(0.0, 0.4, 0.001, "prefer_slider") var c: float
@export_range(0.0, 360.0, 0.1, "prefer_slider") var h: float
@export_range(0.0, 1.0, 0.001, "prefer_slider") var a: float

@export_range(0.0, 1.0, 0.001, "prefer_slider") var stop: float
