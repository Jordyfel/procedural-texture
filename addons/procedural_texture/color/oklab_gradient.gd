@tool
class_name OklabGradient
extends Resource

@export var stops: Array[OklabStop] = []

func get_colors() -> PackedFloat32Array:
	var colors:= PackedFloat32Array()
	for stop in stops:
		var oklab:= Oklab.oklch_to_oklab(Color(stop.l, stop.c, stop.h, stop.a))
		colors.push_back(oklab.r)
		colors.push_back(oklab.g)
		colors.push_back(oklab.b)
		colors.push_back(oklab.a)

	return colors


func get_stops() -> PackedFloat32Array:
	var stops_:= PackedFloat32Array()
	for stop in stops:
		stops_.push_back(stop.stop)

	return stops_


func get_stop_origins() -> PackedFloat32Array:
	var stop_origins:= PackedFloat32Array()
	for stop in stops:
		stop_origins.push_back(stop.stop_origin.x)
		stop_origins.push_back(stop.stop_origin.y)

	return stop_origins
