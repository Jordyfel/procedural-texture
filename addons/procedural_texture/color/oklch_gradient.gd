@tool
class_name OklchGradient
extends Resource

@export var stops: Array[OklchStop] = []

func get_colors() -> PackedVector4Array:
	var colors:= PackedVector4Array()
	colors.resize(8)
	for i in 8:
		if i < stops.size():
			var stop:= stops[i]
			colors[i] = Vector4(stop.l, stop.c, stop.h, stop.a)
		else:
			colors[i] = Vector4()

	return colors


func get_stops() -> PackedFloat32Array:
	var stops_:= PackedFloat32Array()
	stops_.resize(8)
	for i in 8:
		if i < stops.size():
			var stop:= stops[i]
			stops_[i] = stop.stop
		else:
			stops_[i] = 0.0

	return stops_
