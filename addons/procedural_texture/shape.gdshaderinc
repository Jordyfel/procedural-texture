uniform bool outline_enabled;
uniform float outline_width;
uniform vec4 outline_color : source_color;
uniform float outline_smoothstep;

uniform bool fill_enabled;
uniform vec4 fill_color : source_color;
uniform float fill_smoothstep;

vec3 linear_to_srgb(vec3 color) {
	const vec3 a = vec3(0.055f);
	return mix((vec3(1.0f) + a) * pow(color.rgb, vec3(1.0f / 2.4f)) - a, 12.92f * color.rgb,
			lessThan(color.rgb, vec3(0.0031308f)));
}

vec4 blend_premult_alpha(vec4 src, vec4 dst) {
	return vec4(src.rgb + dst.rgb * (1.0 - src.a), src.a + dst.a * (1.0 - src.a));
}

float outline(float gradient, float offset) {
	float outline = smoothstep(offset, offset + outline_smoothstep, gradient);
	float outline_inner = outline_width + offset;
	outline *= smoothstep(outline_inner + outline_smoothstep, outline_inner, gradient);
	return outline;
}

float fill(float gradient, float offset) {
	float fill = smoothstep(offset, offset + fill_smoothstep, gradient);
	return fill;
}

vec4 draw_shape(float sd) {
	vec4 color;

	// Get a gradient from the signed distance.
	float gradient = clamp(-sd, 0.0, 1.0);

	if (outline_enabled) {
		float mask = outline(gradient, 0.01);
		color.a = outline_color.a * mask;
		color.rgb = outline_color.rgb * color.a;
	}

	if (fill_enabled) {
		if (!outline_enabled) {
			float mask = fill(gradient, 0.01);
			color.a = fill_color.a * mask;
			color.rgb = fill_color.rgb * color.a;
		} else { // If both fill and outline are enabled, blend the outline over the fill.
			float offset = 0.01 + outline_width / 2.0;
			float mask = fill(gradient, offset);
			vec4 fill = vec4(fill_color.rgb, fill_color.a * mask);
			fill.rgb *= fill.a;
			color = blend_premult_alpha(color, fill);
			color.rgb *= color.a;
		}
	}

	color.rgb = linear_to_srgb(color.rgb);
	return color;
}
