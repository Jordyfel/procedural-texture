shader_type texture_blit;
render_mode blend_disabled;

#include "res://addons/procedural_texture/color/oklab.gdshaderinc"
#include "res://addons/procedural_texture/sdf_shapes.gdshaderinc"

const int MAX_SHAPE_COUNT = 16;

// TextureNodeShape.Shape
const int SHAPE_CIRCLE = 0;
const int SHAPE_RECTANGLE = 1;

// TextureNodeShape.FillMode
const int MODE_SOLID_COLOR = 0;
const int MODE_DISTANCE_GRADIENT = 1;
const int MODE_LINEAR_GRADIENT = 2;
const int MODE_RADIAL_GRADIENT = 3;
const int MODE_GRADIENT_2D = 4;
const int MODE_OUTLINE_SOLID_COLOR = 5;

const int AVG_STOPS = 4;
const float EDGE_OFFSET = 0.01;

uniform int shape_count;

uniform int shape[MAX_SHAPE_COUNT];
uniform vec4 shape_rect[MAX_SHAPE_COUNT];
uniform vec4 shape_rotation[MAX_SHAPE_COUNT];
uniform vec4 shape_data[MAX_SHAPE_COUNT];

uniform int shape_draw_mode[MAX_SHAPE_COUNT];
uniform float shape_outline_width[MAX_SHAPE_COUNT];
uniform vec4 shape_color[MAX_SHAPE_COUNT];
uniform float shape_smoothing[MAX_SHAPE_COUNT];

uniform int gradient_first_stop[MAX_SHAPE_COUNT];
uniform int gradient_stop_count[MAX_SHAPE_COUNT];
uniform vec4 gradient_colors[MAX_SHAPE_COUNT * AVG_STOPS];
uniform float gradient_stops[MAX_SHAPE_COUNT * AVG_STOPS];

// vec4 linear_gradient_rotation
// OR
// vec2 radial_gradient_origin
// float radial_gradient_radius
uniform vec4 gradient_transform_data[MAX_SHAPE_COUNT];



vec3 linear_to_srgb(vec3 color) {
	const vec3 a = vec3(0.055f);
	return mix((vec3(1.0f) + a) * pow(color.rgb, vec3(1.0f / 2.4f)) - a, 12.92f * color.rgb,
			lessThan(color.rgb, vec3(0.0031308f)));
}

vec4 blend(vec4 src, vec4 dst) {
	float a = src.a + dst.a * (1.0 - src.a);
	vec3 rgb = vec3(src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a));
	return vec4(rgb / a, a);
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
			vec4 r = gradient_transform_data[index];
			mat2 rotation = mat2(vec2(r.x, r.y), vec2(r.z, r.w));
			uv = rotation * (uv - 0.5) + 0.5;
			color = fill_gradient(index, uv.x);
			break;
		case MODE_RADIAL_GRADIENT:
			vec2 origin = gradient_transform_data[index].xy;
			float radius = gradient_transform_data[index].z;
			float radial_sd = length(uv - origin) - radius;
			float radial_gradient = max(-radial_sd * 2.0, 0.0);
			color = fill_gradient(index, radial_gradient);
			break;
		case MODE_GRADIENT_2D:
			// TODO
			break;
	}

	color.a *= fill_mask(gradient, shape_smoothing[index], offset);
	return color;
}

vec4 draw_shape(vec2 uv, int index) {
	vec4 rect = shape_rect[index];
	vec4 r = shape_rotation[index];
	mat2 rotation = mat2(vec2(r.x, r.y), vec2(r.z, r.w));

	uv = (uv - rect.xy) / rect.zw;
	uv = rotation * (uv - 0.5) + 0.5;
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		return vec4(0.0);
	}

	float sd;
	switch (shape[index]) {
		case SHAPE_CIRCLE:
			sd = sd_circle(uv - vec2(0.5));
			break;
		case SHAPE_RECTANGLE:
			sd = sd_rect(uv - vec2(0.5), shape_data[index].xy);

			break;
	}

	vec4 color;

	// Get a gradient from the signed distance.
	float gradient = -sd * 2.0;
	if (gradient < 0.0) {
		return vec4(0.0);
	}

	if (shape_draw_mode[index] == MODE_OUTLINE_SOLID_COLOR) {
		color = shape_color[index];
		float width = shape_outline_width[index];
		color.a *= outline_mask(gradient, width , shape_smoothing[index], EDGE_OFFSET);
	} else {
		color = make_fill_color(uv, index, gradient, EDGE_OFFSET);
	}

	return color;
}

void blit() {
	vec4 color = MODULATE;

	int count = min(shape_count, MAX_SHAPE_COUNT);
	for (int index = 0; index < count; index++) {
		vec4 new_color = draw_shape(UV, index);
		color = blend(new_color, color);
	}

	color.rgb = oklab_to_linear(color.rgb);
	color.rgb = linear_to_srgb(color.rgb);

	COLOR0 = color;
}
