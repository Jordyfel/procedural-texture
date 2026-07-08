shader_type canvas_item;

float sdCircle(vec2 uv) {
    return length(uv) - 0.5;
}

void fragment() {
	float gradient = clamp(-sdCircle(UV - vec2(0.5)), 0.0, 1.0);
	float mask = smoothstep(0.09, 0.11, gradient);
	COLOR = vec4(vec3(gradient), 1.0);
}
