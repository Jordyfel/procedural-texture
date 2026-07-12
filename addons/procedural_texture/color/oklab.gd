@tool
class_name Oklab
extends RefCounted


static func oklab_to_oklch(oklab: Color) -> Color:
	return Color(
		oklab.r,
		sqrt(oklab.g * oklab.g + oklab.b * oklab.b),
		(atan2(oklab.b, oklab.g) * 180.0) / PI,
		oklab.a
	)


static func oklch_to_oklab(oklch: Color) -> Color:
	return Color(
		oklch.r,
		oklch.g * cos((oklch.b * PI) / 180.0),
		oklch.g * sin((oklch.b * PI) / 180.0),
		oklch.a
	)


static func linear_to_oklab(color: Color) -> Color:
	@warning_ignore("shadowed_variable")
	var l:= 0.4122214708 * color.r + 0.5363325363 * color.g + 0.0514459929 * color.b;
	var m:= 0.2119034982 * color.r + 0.6806995451 * color.g + 0.1073969566 * color.b;
	var s:= 0.0883024619 * color.r + 0.2817188376 * color.g + 0.6299787005 * color.b;

	var l_:= pow(l, 1.0 / 3.0)
	var m_:= pow(m, 1.0 / 3.0)
	var s_:= pow(s, 1.0 / 3.0)

	return Color(
		0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_,
		1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_,
		0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_,
		color.a
	)


static func oklab_to_linear(oklab: Color) -> Color:
	var l_:= oklab.r + 0.3963377774 * oklab.g + 0.2158037573 * oklab.b
	var m_:= oklab.r - 0.1055613458 * oklab.g - 0.0638541728 * oklab.b
	var s_:= oklab.r - 0.0894841775 * oklab.g - 1.2914855480 * oklab.b

	@warning_ignore("shadowed_variable")
	var l:= pow(l_, 3.0)
	var m:= pow(m_, 3.0)
	var s:= pow(s_, 3.0)

	return Color(
		+4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
		-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
		-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
		oklab.a
	)
