#include "res://addons/procedural_texture/color/oklch.gdshaderinc"

const int MAX_STOPS = 8;
const float STOP_UNSET = 10.0;
const float EDGE_OFFSET = 0.01;

uniform bool outline_enabled;
uniform float outline_width;
uniform vec4 outline_color : source_color;
uniform float outline_smoothstep;

uniform bool fill_enabled;
uniform vec4 fill_color : source_color;
uniform bool fill_use_gradient;
uniform vec4 fill_gradient_colors[MAX_STOPS];
uniform float fill_gradient_stops[MAX_STOPS];
uniform float fill_smoothstep;

vec3 linear_to_srgb(vec3 color) {
	const vec3 a = vec3(0.055f);
	return mix((vec3(1.0f) + a) * pow(color.rgb, vec3(1.0f / 2.4f)) - a, 12.92f * color.rgb,
			lessThan(color.rgb, vec3(0.0031308f)));
}

vec4 blend_premult_alpha(vec4 src, vec4 dst) {
	return vec4(src.rgb + dst.rgb * (1.0 - src.a), src.a + dst.a * (1.0 - src.a));
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

	color.rgb = oklch_to_linear(color.rgb);
	return color;
}

vec4 draw_shape(float sd) {
	vec4 color;

	// Get a gradient from the signed distance.
	float gradient = clamp(-sd * 2.0, 0.0, 1.0);

	if (outline_enabled) {
		color = outline_color;
		color.a *= outline_mask(gradient, EDGE_OFFSET);
	}

	if (fill_enabled) {
		if (!outline_enabled) {
			color = fill_use_gradient ? fill_gradient(gradient) : fill_color;
			color.a *= fill_mask(gradient, EDGE_OFFSET);
		} else { // If both fill and outline are enabled, blend the outline over the fill.
			vec4 fill_result = fill_use_gradient ? fill_gradient(gradient) : fill_color;
			float offset = EDGE_OFFSET + outline_width / 2.0;
			fill_result.a *= fill_mask(gradient, offset);

			color.rgb *= color.a;
			color = blend_premult_alpha(color, fill_result);
		}
	}

	color.rgb = linear_to_srgb(color.rgb);
	color.rgb *= color.a;
	return color;
}
