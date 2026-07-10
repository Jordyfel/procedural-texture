shader_type texture_blit;
render_mode blend_premul_alpha;

#include "res://addons/procedural_texture/color/oklab.gdshaderinc"
#include "res://addons/procedural_texture/sdf_shapes.gdshaderinc"

// TextureNodeShape.Shape
const int SHAPE_CIRCLE = 0;
const int SHAPE_RECTANGLE = 1;

// TextureNodeShape.FillMode
const int MODE_SOLID_COLOR = 0;
const int MODE_DISTANCE_GRADIENT = 1;
const int MODE_LINEAR_GRADIENT = 2;
const int MODE_RADIAL_GRADIENT = 3;
const int MODE_GRADIENT_2D = 4;

const int MAX_STOPS = 8;
const float STOP_UNSET = 10.0;
const float EDGE_OFFSET = 0.01;

uniform int shape;

uniform vec2 rect;

uniform bool outline_enabled;
uniform float outline_width;
uniform vec4 outline_color;
uniform float outline_smoothstep;

uniform bool fill_enabled;
uniform int fill_mode;
uniform vec4 fill_color;
uniform vec4 fill_gradient_colors[MAX_STOPS];
uniform float fill_gradient_stops[MAX_STOPS];
uniform mat2 linear_gradient_rotation;
uniform vec2 radial_gradient_origin;
uniform float radial_gradient_radius;
uniform float fill_smoothstep;

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

float outline_mask(float gradient, float offset) {
	float outline = smoothstep(offset, offset + outline_smoothstep, gradient);
	float outline_inner = outline_width + offset;
	outline *= smoothstep(outline_inner + outline_smoothstep, outline_inner, gradient);
	return outline;
}

float fill_mask(float gradient, float offset) {
	float fill = smoothstep(offset, offset + fill_smoothstep, gradient);
	return fill;
}

vec4 fill_gradient(float gradient) {
	int next_stop_index = -1;
	for (int i = 0; i < fill_gradient_stops.length(); i++) {
		if (fill_gradient_stops[i] > gradient) {
			next_stop_index = i;
			break;
		}
	}

	vec4 color;
	if (next_stop_index == 0) { // First color.
		color = vec4(fill_gradient_colors[0]);
	} else if (next_stop_index == -1) { // Last Color when full.
		color = vec4(fill_gradient_colors[MAX_STOPS - 1]);
	} else if (fill_gradient_stops[next_stop_index] > STOP_UNSET) { // Last Color when not full.
		color = vec4(fill_gradient_colors[next_stop_index - 1]);
	} else { // Interpolate.
		float prev_stop = fill_gradient_stops[next_stop_index - 1];
		float next_stop = fill_gradient_stops[next_stop_index];
		float factor = (gradient - prev_stop) / (next_stop - prev_stop);

		vec4 prev_color = fill_gradient_colors[next_stop_index - 1];
		vec4 next_color = fill_gradient_colors[next_stop_index];
		color = mix(prev_color, next_color, factor);
	}

	return color;
}

vec4 make_fill_color(vec2 uv, float gradient, float offset) {
	vec4 color;
	switch (fill_mode) {
		case MODE_SOLID_COLOR:
			color = fill_color;
			break;
		case MODE_DISTANCE_GRADIENT:
			color = fill_gradient(gradient);
			break;
		case MODE_LINEAR_GRADIENT:
			vec2 rot = linear_gradient_rotation * (uv - 0.5) + 0.5;
			color = fill_gradient(rot.x);
			break;
		case MODE_RADIAL_GRADIENT:
			float radial_sd = length(uv - radial_gradient_origin) - radial_gradient_radius;
			float radial_gradient = max(-radial_sd * 2.0, 0.0);
			color = fill_gradient(radial_gradient);
			break;
		case MODE_GRADIENT_2D:
			// TODO
			break;
	}

	color.a *= fill_mask(gradient, offset);
	return color;
}

vec4 draw_shape(vec2 uv, float sd) {
	vec4 color;

	// Get a gradient from the signed distance.
	float gradient = clamp(-sd * 2.0, 0.0, 1.0);

	if (outline_enabled) {
		color = outline_color;
		color.a *= outline_mask(gradient, EDGE_OFFSET);
	}

	if (fill_enabled) {
		if (!outline_enabled) {
			color = make_fill_color(uv, gradient, EDGE_OFFSET);
		} else { // If both fill and outline are enabled, blend the outline over the fill.
			float offset = EDGE_OFFSET + outline_width / 2.0;
			vec4 fill_result = make_fill_color(uv, gradient, offset);
			color = blend(color, fill_result);
		}
	}

	color.rgb = oklab_to_linear(color.rgb);
	color.rgb = linear_to_srgb(color.rgb);
	color.rgb *= color.a;
	return color;
}

void blit() {
	vec2 uv = UV - vec2(0.5);
	float sd;
	switch (shape) {
		case SHAPE_CIRCLE:
			sd = sd_circle(uv);
			break;
		case SHAPE_RECTANGLE:
			sd = sd_rect(uv, rect);
			break;
	}

	COLOR0 = draw_shape(UV, sd);
}
