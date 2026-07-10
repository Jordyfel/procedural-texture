@tool
@abstract class_name TextureNodeShape
extends TextureNode

# Keep in sync with constants in shape.gdshaderinc.
enum FillMode {SOLID_COLOR, DISTANCE_GRADIENT, LINEAR_GRADIENT, RADIAL_GRADIENT, GRADIENT_2D}

@export_group("Outline", "outline")
@export_custom(PROPERTY_HINT_GROUP_ENABLE,"") var outline_enabled:= false:
	set(value):
		outline_enabled = value
		emit_changed()

@export_range(0, 20, 0.01, "or_greater", "prefer_slider") var outline_width:= 2.0:
	set(value):
		outline_width = value
		emit_changed()

@export var outline_color:= Color.BLACK:
	set(value):
		outline_color = value
		emit_changed()

@export_range(0, 10, 0.01, "or_greater", "prefer_slider") var outline_smoothing_factor:= 1.2:
	set(value):
		outline_smoothing_factor = value
		emit_changed()


@export_group("Fill", "fill")
@export_custom(PROPERTY_HINT_GROUP_ENABLE,"") var fill_enabled:= false:
	set(value):
		fill_enabled = value
		emit_changed()

@export var fill_mode:= FillMode.SOLID_COLOR:
	set(value):
		fill_mode = value
		emit_changed()

@export var fill_color:= Color.WHITE:
	set(value):
		fill_color = value
		emit_changed()

@export var fill_gradient:= OklchGradient.new():
	set(value):
		fill_gradient = value
		emit_changed()

@export_range(0, 10, 0.01, "or_greater", "prefer_slider") var fill_smoothing_factor:= 1.2:
	set(value):
		fill_smoothing_factor = value
		emit_changed()


func _set_material_parameters() -> void:
	var side_length:= _get_width() as float

	RenderingServer.material_set_param(material, "outline_enabled", outline_enabled)
	var outline_width_normalized:= outline_width / side_length
	RenderingServer.material_set_param(material, "outline_width", outline_width_normalized)
	RenderingServer.material_set_param(material, "outline_color", get_oklab(outline_color))
	var outline_smoothstep:= outline_smoothing_factor / side_length
	RenderingServer.material_set_param(material, "outline_smoothstep", outline_smoothstep)

	RenderingServer.material_set_param(material, "fill_enabled", fill_enabled)
	RenderingServer.material_set_param(material, "fill_mode", fill_mode)
	RenderingServer.material_set_param(material, "fill_color", get_oklab(fill_color))
	RenderingServer.material_set_param(material, "fill_gradient_colors", fill_gradient.get_colors())
	RenderingServer.material_set_param(material, "fill_gradient_stops", fill_gradient.get_stops())
	var fill_smoothstep:= fill_smoothing_factor / side_length
	RenderingServer.material_set_param(material, "fill_smoothstep", fill_smoothstep)


func get_oklab(color: Color) -> Vector4:
	var oklab:= Oklch.linear_to_oklab(color.srgb_to_linear())
	return Vector4(oklab.l, oklab.a, oklab.b, oklab.alpha)
