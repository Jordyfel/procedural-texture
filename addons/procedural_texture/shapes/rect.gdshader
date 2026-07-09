shader_type texture_blit;
render_mode blend_premul_alpha;

#include "res://addons/procedural_texture/shape.gdshaderinc"

uniform vec2 rect;

float sd_rect(in vec2 p, in vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x ,d.y), 0.0);
}

void blit() {
	float sd = sd_rect(UV - vec2(0.5), rect);
	COLOR0 = draw_shape(sd);
}
