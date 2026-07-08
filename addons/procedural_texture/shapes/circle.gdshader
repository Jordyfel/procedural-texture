shader_type texture_blit;
render_mode blend_premul_alpha;

#include "res://addons/procedural_texture/shape.gdshaderinc"

float sd_circle(vec2 uv) {
    return length(uv) - 0.5;
}

void blit() {
	float sd = sd_circle(UV - vec2(0.5));
	COLOR0 = draw_shape(sd);
}
