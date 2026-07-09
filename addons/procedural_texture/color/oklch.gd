@tool
class_name Oklch
extends Node

var l: float
var c: float
var h: float
var a: float


func _init(p_l: float, p_c: float, p_h: float, p_a: float) -> void:
	l = p_l
	c = p_c
	h = p_h
	a = p_a


static func linear_to_oklch(color: Color) -> Oklch:
	@warning_ignore("shadowed_variable")
	var l:= 0.4122214708 * color.r + 0.5363325363 * color.g + 0.0514459929 * color.b;
	var m:= 0.2119034982 * color.r + 0.6806995451 * color.g + 0.1073969566 * color.b;
	var s:= 0.0883024619 * color.r + 0.2817188376 * color.g + 0.6299787005 * color.b;

	var l_:= pow(l, 1.0 / 3.0)
	var m_:= pow(m, 1.0 / 3.0)
	var s_:= pow(s, 1.0 / 3.0)

	var l2:= 0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_
	var a2:= 1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_
	var b2:= 0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_

	return Oklch.new(
		l2,
		sqrt(a2 * a2 + b2 * b2),
		(atan2(b2, a2) * 180.0) / PI,
		color.a
	)


static func oklch_to_linear(oklch: Oklch) -> Color:
	var l2:= oklch.l
	var a2:= oklch.c * cos((oklch.h * PI) / 180.0)
	var b2:= oklch.c * sin((oklch.h * PI) / 180.0)

	var l_:= l2 + 0.3963377774 * a2 + 0.2158037573 * b2
	var m_:= l2 - 0.1055613458 * a2 - 0.0638541728 * b2
	var s_:= l2 - 0.0894841775 * a2 - 1.2914855480 * b2;

	@warning_ignore("shadowed_variable")
	var l:= pow(l_, 3.0)
	var m:= pow(m_, 3.0)
	var s:= pow(s_, 3.0)

	return Color(
		+4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
		-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
		-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
		oklch.a
	)
