shader_type texture_blit;
render_mode blend_disabled;

#include "color/oklab.gdshaderinc"
#include "sdf_shapes.gdshaderinc"

const int MAX_INSTANCE_COUNT = 64;
const int AVG_SHAPE_DATA = 8;
const int AVG_STOPS = 4;

const int SHAPE_CIRCLE = 0;                                 // TextureNodeShape.Shape
const int SHAPE_RECTANGLE = 1;
const int SHAPE_RHOMBUS = 2;

const int MODE_SOLID_COLOR = 0;                             // TextureNodeShape.FillMode
const int MODE_DISTANCE_GRADIENT = 1;
const int MODE_LINEAR_GRADIENT = 2;
const int MODE_RADIAL_GRADIENT = 3;
const int MODE_OUTLINE_SOLID_COLOR = 4;

const float EDGE_OFFSET = 0.01;

uniform int shape_count;

uniform int shape[MAX_INSTANCE_COUNT];                         // Type.

uniform vec4 shape_rect[MAX_INSTANCE_COUNT];                   // Transform.
uniform float shape_rotation[MAX_INSTANCE_COUNT];

uniform int shape_draw_mode[MAX_INSTANCE_COUNT];               // Draw data.
uniform float shape_outline_width[MAX_INSTANCE_COUNT];
uniform vec4 shape_color[MAX_INSTANCE_COUNT];
uniform float shape_smoothing[MAX_INSTANCE_COUNT];
uniform float shape_rounding[MAX_INSTANCE_COUNT];

// float linear_gradient_rotation
// OR
// vec2 radial_gradient_origin
// float radial_gradient_radius
uniform vec3 draw_mode_data[MAX_INSTANCE_COUNT];

uniform int shape_data_start[MAX_INSTANCE_COUNT];              // Shape data slice and global array.
uniform int shape_data_count[MAX_INSTANCE_COUNT];
uniform float shape_data[MAX_INSTANCE_COUNT * AVG_SHAPE_DATA];

uniform int gradient_first_stop[MAX_INSTANCE_COUNT];           // Gradients slice and global array.
uniform int gradient_stop_count[MAX_INSTANCE_COUNT];
uniform vec4 gradient_colors[MAX_INSTANCE_COUNT * AVG_STOPS];
uniform float gradient_stops[MAX_INSTANCE_COUNT * AVG_STOPS];  // Or weights for 2D gradients.


vec3 linear_to_srgb(vec3 color) {
	const vec3 a = vec3(0.055f);
	return mix((vec3(1.0f) + a) * pow(color.rgb, vec3(1.0f / 2.4f)) - a, 12.92f * color.rgb,
			lessThan(color.rgb, vec3(0.0031308f)));
}

vec4 blend_premult_alpha(vec4 src, vec4 dst) {
	return vec4(vec3(src.rgb + dst.rgb * (1.0 - src.a)), src.a + dst.a * (1.0 - src.a));
}

float outline_mask(float gradient, float width, float smoothing, float offset) {
	float outline = smoothstep(offset, offset + smoothing, gradient);
	float outline_inner = width + offset;
	outline *= smoothstep(outline_inner + smoothing, outline_inner, gradient);
	return outline;
}

float fill_mask(float gradient, float smoothing, float offset) {
	float fill = smoothstep(offset, offset + smoothing, gradient);
	return fill;
}

vec4 fill_gradient(int index, float gradient) {
	int next_stop_index = -1;
	int first_stop = gradient_first_stop[index];
	int last_stop = first_stop + gradient_stop_count[index] - 1;
	for (int i = first_stop; i <= last_stop; i++) {
		if (gradient_stops[i] > gradient) {
			next_stop_index = i;
			break;
		}
	}

	vec4 color;
	if (next_stop_index == first_stop) { // First color.
		color = vec4(gradient_colors[first_stop]);
	} else if (next_stop_index == -1) { // Last Color.
		color = vec4(gradient_colors[last_stop]);
	} else { // Interpolate.
		float prev_stop = gradient_stops[next_stop_index - 1];
		float next_stop = gradient_stops[next_stop_index];
		float factor = (gradient - prev_stop) / (next_stop - prev_stop);

		vec4 prev_color = gradient_colors[next_stop_index - 1];
		vec4 next_color = gradient_colors[next_stop_index];
		color = mix(prev_color, next_color, factor);
	}

	return color;
}

vec4 make_fill_color(vec2 uv, int index, float gradient, float offset) {
	vec4 color;
	switch (shape_draw_mode[index]) {
		case MODE_SOLID_COLOR:
			color = shape_color[index];
			break;
		case MODE_DISTANCE_GRADIENT:
			color = fill_gradient(index, gradient);
			break;
		case MODE_LINEAR_GRADIENT:
			float r = draw_mode_data[index].x;
			float c = cos(r);
			float s = sin(r);
			mat2 rotation = mat2(vec2(c, -s), vec2(s, c));
			uv = rotation * (uv - 0.5) + 0.5;
			color = fill_gradient(index, uv.x);
			break;
		case MODE_RADIAL_GRADIENT:
			vec2 origin = draw_mode_data[index].xy;
			float radius = draw_mode_data[index].z;
			float radial_sd = length(uv - origin) - radius;
			float radial_gradient = max(-radial_sd * 2.0, 0.0);
			color = fill_gradient(index, radial_gradient);
			break;
	}

	color *= fill_mask(gradient, shape_smoothing[index], offset);
	return color;
}

float get_shape_signed_distance(vec2 uv, int index) {
	vec2 p = uv - vec2(0.5);
	float scale = 1.0 + shape_rounding[index] * 2.0;
	p *= vec2(scale);

	int data_start = shape_data_start[index];
	float sd;
	switch (shape[index]) {
		case SHAPE_CIRCLE:
			sd = sdCircle(p, 0.5);
			break;
		case SHAPE_RECTANGLE:
			vec2 b = vec2(shape_data[data_start], shape_data[data_start + 1]);
			sd = sdBox(p, b);
			break;
		case SHAPE_RHOMBUS:
			vec2 b = vec2(shape_data[data_start], shape_data[data_start + 1]);
			sd = sdRhombus(p, b);
			break;
	}

	sd -= shape_rounding[index];
	sd /= scale;
	return sd;
}

vec4 draw_shape(vec2 uv, int index) {
	vec4 rect = shape_rect[index];

	float r = shape_rotation[index];
	float c = cos(r);
	float s = sin(r);
	mat2 rotation = mat2(vec2(c, -s), vec2(s, c));

	uv = (uv - rect.xy) / rect.zw;
	uv = rotation * (uv - 0.5) + 0.5;
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		return vec4(0.0);
	}

	float sd = get_shape_signed_distance(uv, index);
	if (sd > 0.0) {
		return vec4(0.0);
	}

	float gradient = -sd * 2.0;

	vec4 color;

	if (shape_draw_mode[index] == MODE_OUTLINE_SOLID_COLOR) {
		color = shape_color[index];
		float width = shape_outline_width[index];
		color *= outline_mask(gradient, width , shape_smoothing[index], EDGE_OFFSET);
	} else {
		color = make_fill_color(uv, index, gradient, EDGE_OFFSET);
	}

	return color;
}

void blit() {
	vec4 color = MODULATE;

	int count = min(shape_count, MAX_INSTANCE_COUNT);
	for (int index = 0; index < count; index++) {
		vec4 new_color = draw_shape(UV, index);
		color = blend_premult_alpha(new_color, color);
	}

	color.rgb /= color.a;
	color.rgb = oklab_to_linear(color.rgb);
	color.rgb = linear_to_srgb(color.rgb);

	COLOR0 = color;
}
