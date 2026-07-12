@tool
class_name ShapeMaterialParameters
extends RefCounted

const AVG_GRADIENT_STOPS = 4
const AVG_SHAPE_DATA = 8


static var instance_parameter_names: Array[StringName] = [
	&"shape",
	&"shape_rect",
	&"shape_rotation",
	&"shape_data_start",
	&"shape_data_count",
	&"shape_draw_mode",
	&"shape_outline_width",
	&"shape_color",
	&"shape_smoothing",
	&"gradient_first_stop",
	&"gradient_stop_count",
	&"gradient_transform_data",
]

static var array_parameter_names: Array[StringName] = [
	&"shape_data",
	&"gradient_colors",
	&"gradient_stops",
	&"gradient_stop_origins",
]

static var material_parameter_size_in_bytes_map: Dictionary[StringName, int] = {
	&"shape":                   4,
	&"shape_rect":              16,
	&"shape_rotation":          4,
	&"shape_data_start":        4,
	&"shape_data_count":        4,
	&"shape_data":              4 * AVG_SHAPE_DATA,
	&"shape_draw_mode":         4,
	&"shape_outline_width":     4,
	&"shape_color":             16,
	&"shape_smoothing":         4,
	&"gradient_first_stop":     4,
	&"gradient_stop_count":     4,
	&"gradient_colors":         16 * AVG_GRADIENT_STOPS,
	&"gradient_stops":          4 * AVG_GRADIENT_STOPS,
	&"gradient_stop_origins":   8 * AVG_GRADIENT_STOPS,
	&"gradient_transform_data": 12,
}


static func convert_parameter_array(param_name: StringName, array: PackedByteArray) -> Variant:
	match param_name:
		&"shape":                   return array.to_int32_array()
		&"shape_rect":              return array.to_vector4_array()
		&"shape_rotation":          return array.to_float32_array()
		&"shape_data_start":        return array.to_int32_array()
		&"shape_data_count":        return array.to_int32_array()
		&"shape_data":              return array.to_float32_array()
		&"shape_draw_mode":         return array.to_int32_array()
		&"shape_outline_width":     return array.to_float32_array()
		&"shape_color":             return array.to_vector4_array()
		&"shape_smoothing":         return array.to_float32_array()
		&"gradient_first_stop":     return array.to_int32_array()
		&"gradient_stop_count":     return array.to_int32_array()
		&"gradient_colors":         return array.to_vector4_array()
		&"gradient_stops":          return array.to_float32_array()
		&"gradient_stop_origins":   return array.to_vector2_array()
		&"gradient_transform_data": return array.to_vector3_array()
	return null
