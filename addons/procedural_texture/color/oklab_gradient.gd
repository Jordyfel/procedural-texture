@tool
class_name OklabGradient
extends Resource

@export var stops: Array[OklabStop] = []

func get_colors() -> PackedFloat32Array:
	var colors:= PackedFloat32Array()
	for stop in stops:
		var oklab:= Oklab.oklch_to_oklab(Color(stop.l, stop.c, stop.h, stop.a))
		colors.push_back(oklab.r * oklab.a)
		colors.push_back(oklab.g * oklab.a)
		colors.push_back(oklab.b * oklab.a)
		colors.push_back(oklab.a)

	return colors


func get_stops() -> PackedFloat32Array:
	var stops_:= PackedFloat32Array()
	for stop in stops:
		stops_.push_back(stop.stop)

	return stops_
