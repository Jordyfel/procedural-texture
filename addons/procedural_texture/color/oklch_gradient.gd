@tool
class_name OklchGradient
extends Resource

@export var stops: Array[OklchStop] = []

func get_colors() -> PackedVector4Array:
	var colors:= PackedVector4Array()
	for stop in stops:
		var oklab:= Oklch.oklch_to_oklab(Oklch.new(stop.l, stop.c, stop.h, stop.a))
		colors.push_back(Vector4(oklab.l, oklab.a, oklab.b, oklab.alpha))

	return colors


func get_stops() -> PackedFloat32Array:
	var stops_:= PackedFloat32Array()
	for stop in stops:
		stops_.push_back(stop.stop)

	return stops_


func get_stop_origins() -> PackedVector2Array:
	var stop_origins:= PackedVector2Array()
	for stop in stops:
		stop_origins.push_back(stop.stop_origin)

	return stop_origins
