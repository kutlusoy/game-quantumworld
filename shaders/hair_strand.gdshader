shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 light_dir = vec3(0.4, 0.8, 0.45);
uniform vec3 shadow_tint : source_color = vec3(0.6, 0.52, 0.85);
uniform vec3 hl_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 edge_color : source_color = vec3(0.07, 0.04, 0.12);

varying vec3 world_normal;

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = FRONT_FACING ? world_normal : -world_normal;
	float l = dot(n, normalize(light_dir));
	float s = step(0.25, l) * 0.55 + step(-0.3, l) * 0.3 + 0.15;
	vec3 col = COLOR.rgb * mix(shadow_tint, vec3(1.0), s);
	float band = smoothstep(0.3, 0.34, UV.y) * (1.0 - smoothstep(0.46, 0.5, UV.y));
	band += 0.6 * smoothstep(0.7, 0.73, UV.y) * (1.0 - smoothstep(0.78, 0.8, UV.y));
	col = mix(col, hl_color, band * 0.38 * step(0.0, l + 0.4));
	float edge = smoothstep(0.0, 0.1, UV.x) * smoothstep(0.0, 0.1, 1.0 - UV.x);
	col = mix(edge_color, col, edge);
	ALBEDO = col;
}
