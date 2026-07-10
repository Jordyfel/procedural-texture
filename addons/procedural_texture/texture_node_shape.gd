@tool
@abstract class_name TextureNodeShape
extends TextureNode

enum Shape {CIRCLE, RECTANGLE}

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

@export_range(0, 360, 0.001, "radians_as_degrees") var fill_linear_gradient_rotation:= 0.0:
	set(value):
		fill_linear_gradient_rotation = value
		emit_changed()

@export var fill_radial_gradient_origin:= Vector2(0.5, 0.5):
	set(value):
		fill_radial_gradient_origin = value
		emit_changed()

@export_range(0, 1.0, 0.001, "or_greater", "prefer_slider") var fill_radial_gradient_radius:= 0.5:
	set(value):
		fill_radial_gradient_radius = value
		emit_changed()

@export_range(0, 10, 0.01, "or_greater", "prefer_slider") var fill_smoothing_factor:= 1.2:
	set(value):
		fill_smoothing_factor = value
		emit_changed()


static func create(shape: Shape) -> TextureNodeShape:
	match shape:
		Shape.CIRCLE:
			return CircleShape.new()
		Shape.RECTANGLE:
			return RectShape.new()
		_:
			return CircleShape.new()


func _get_shape() -> Shape:
	return Shape.CIRCLE


func _get_shape_data() -> Vector4:
	return Vector4()
