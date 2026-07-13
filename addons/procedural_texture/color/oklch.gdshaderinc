// https://bottosson.github.io/posts/oklab/

vec3 oklab_to_oklch(vec3 color) {
	float l = color.x;
	float c = sqrt(color.y * color.y + color.z * color.z);
	float h = (atan(color.z, color.y) * 180.0) / PI;

	return vec3(l, c, h);
}

vec3 oklch_to_oklab(vec3 color) {
	float l = color.x;
	float a = color.y * cos((color.z * PI) / 180.0);
	float b = color.y * sin((color.z * PI) / 180.0);

	return vec3(l, a, b);
}
