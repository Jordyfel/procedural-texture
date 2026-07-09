uniform bool outline_enabled;
uniform float outline_width;
uniform vec4 outline_color : source_color;
uniform float outline_smoothstep;

uniform bool fill_enabled;
uniform vec4 fill_color : source_color;
uniform bool fill_use_gradient;
uniform vec4 fill_gradient_colors[8];
uniform vec4 fill_gradient_stops[8];
uniform float fill_smoothstep;

vec3 linear_to_srgb(vec3 color) {
	const vec3 a = vec3(0.055f);
	return mix((vec3(1.0f) + a) * pow(color.rgb, vec3(1.0f / 2.4f)) - a, 12.92f * color.rgb,
			lessThan(color.rgb, vec3(0.0031308f)));
}

vec4 blend_premult_alpha(vec4 src, vec4 dst) {
	return vec4(src.rgb + dst.rgb * (1.0 - src.a), src.a + dst.a * (1.0 - src.a));
}

vec4 outline(float gradient, float offset) {
	float mask = smoothstep(offset, offset + outline_smoothstep, gradient);
	float outline_inner = outline_width + offset;
	mask *= smoothstep(outline_inner + outline_smoothstep, outline_inner, gradient);
	float a = outline_color.a * mask;
	return vec4(outline_color.rgb * a, a);
}

vec4 fill(float gradient, float offset) {
	float mask = smoothstep(offset, offset + fill_smoothstep, gradient);
	float a = fill_color.a * mask;
	return vec4(fill_color.rgb * a, a);
}

vec4 draw_shape(float sd) {
	vec4 color;

	// Get a gradient from the signed distance.
	float gradient = clamp(-sd, 0.0, 1.0);

	if (outline_enabled) {
		color = outline(gradient, 0.01);
	}

	if (fill_enabled) {
		if (!outline_enabled) {
			color = fill(gradient, 0.01);
		} else { // If both fill and outline are enabled, blend the outline over the fill.
			float offset = 0.01 + outline_width / 2.0;
			vec4 fill = fill(gradient, offset);
			color = blend_premult_alpha(color, fill);
			color.rgb *= color.a;
		}
	}

	color.rgb = linear_to_srgb(color.rgb);
	return color;
}
