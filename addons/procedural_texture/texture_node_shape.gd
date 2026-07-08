@tool
@abstract class_name TextureNodeShape
extends TextureNode

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

@export var fill_color:= Color.WHITE:
	set(value):
		fill_color = value
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
	RenderingServer.material_set_param(material, "outline_color", outline_color)
	var outline_smoothstep:= outline_smoothing_factor / side_length
	RenderingServer.material_set_param(material, "outline_smoothstep", outline_smoothstep)

	RenderingServer.material_set_param(material, "fill_enabled", fill_enabled)
	RenderingServer.material_set_param(material, "fill_color", fill_color)
	var fill_smoothstep:= fill_smoothing_factor / side_length
	RenderingServer.material_set_param(material, "fill_smoothstep", fill_smoothstep)
