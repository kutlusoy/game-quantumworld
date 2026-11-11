shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 light_dir = vec3(0.4, 0.8, 0.45);
uniform vec3 shadow_tint : source_color = vec3(0.66, 0.58, 0.9);
uniform float rim_strength = 0.28;

varying vec3 world_normal;

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float l = dot(world_normal, normalize(light_dir));
	float s = step(0.3, l) * 0.55 + step(-0.25, l) * 0.3 + 0.15;
	vec3 col = COLOR.rgb * mix(shadow_tint, vec3(1.0), s);
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	col += fres * rim_strength * vec3(1.0, 0.92, 1.0);
	ALBEDO = col;
}
