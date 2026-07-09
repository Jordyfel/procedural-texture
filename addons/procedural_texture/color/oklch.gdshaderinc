const mat3 RGB_TO_LMS = mat3(
	vec3(+0.4122214708, +0.2119034982, +0.0883024619),
	vec3(+0.5363325363, +0.6806995451, +0.2817188376),
	vec3(+0.0514459929, +0.1073969566, +0.6299787005)
);

const mat3 LMS_CBRT_TO_OKLAB = mat3(
	vec3(+0.2104542553, +1.9779984951, +0.0259040371),
	vec3(+0.7936177850, -2.4285922050, +0.7827717662),
	vec3(-0.0040720468, +0.4505937099, -0.8086757660)
);

const mat3 OKLAB_TO_LMS_CBRT = mat3(
	vec3(1.0),
	vec3(+0.3963377774, -0.1055613458, -0.0894841775),
	vec3(+0.2158037573, -0.0638541728, -1.2914855480)
);

const mat3 LMS_TO_RGB = mat3(
	vec3(+4.0767416621, -1.2684380046, -0.0041960863),
	vec3(-3.3077115913, +2.6097574011, -0.7034186147),
	vec3(+0.2309699292, -0.3413193965, +1.7076147010)
);

vec3 linear_to_oklch(vec3 color) {
	vec3 lms = RGB_TO_LMS * color;
	vec3 lms_cbrt = pow(lms, vec3(1.0 / 3.0));
	vec3 oklab = LMS_CBRT_TO_OKLAB * lms_cbrt;

	float l = oklab.x;
	float c = sqrt(oklab.y * oklab.y + oklab.z * oklab.z);
	float h = (atan(oklab.z, oklab.y) * 180.0) / PI;

	return vec3(l, c, h);
}

vec3 oklch_to_linear(vec3 color) {
	float l = color.x;
	float a = color.y * cos((color.z * PI) / 180.0);
	float b = color.y * sin((color.z * PI) / 180.0);

	vec3 oklab = vec3(l, a, b);
	vec3 lms_cbrt = OKLAB_TO_LMS_CBRT * oklab;
	vec3 lms = pow(lms_cbrt, vec3(3.0));

	return LMS_TO_RGB * lms;
}
