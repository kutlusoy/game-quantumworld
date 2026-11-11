shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 light_dir = vec3(0.45, 0.8, 0.35);
uniform vec3 shadow_tint : source_color = vec3(0.62, 0.55, 0.85);

varying vec3 world_normal;

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float l = dot(world_normal, normalize(light_dir));
	float s = step(0.45, l) * 0.55 + step(-0.25, l) * 0.3 + 0.15;
	ALBEDO = COLOR.rgb * mix(shadow_tint, vec3(1.0), s);
}
