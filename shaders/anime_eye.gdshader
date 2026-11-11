shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque;

uniform vec3 iris_top : source_color = vec3(0.3, 0.1, 0.4);
uniform vec3 iris_bottom : source_color = vec3(1.0, 0.5, 0.8);
uniform vec3 lash_color : source_color = vec3(0.07, 0.04, 0.1);
uniform float open = 1.0;
uniform float flip = 1.0;
uniform vec2 look = vec2(0.0, 0.0);

float circle(vec2 p, vec2 c, float r, float soft) {
	return 1.0 - smoothstep(r - soft, r + soft, length(p - c));
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.x *= flip;
	p.y = -p.y;
	float w = clamp(1.0 - p.x * p.x, 0.0, 1.0);
	float top = 0.88 * pow(w, 0.55) * open * (1.0 + 0.12 * p.x);
	float bot = -0.78 * pow(w, 0.75);
	float inside = smoothstep(bot - 0.03, bot + 0.03, p.y) * (1.0 - smoothstep(top - 0.03, top + 0.03, p.y));
	vec2 c = vec2(look.x * 0.18 + 0.02, look.y * 0.12 - 0.04);
	vec2 q = vec2(p.x - c.x, (p.y - c.y) / 1.2);
	float d = length(q);
	float iris = 1.0 - smoothstep(0.6, 0.64, d);
	float t = clamp((c.y - p.y) / 1.3 + 0.5, 0.0, 1.0);
	vec3 iris_col = mix(iris_top, iris_bottom, t);
	iris_col = mix(iris_col, iris_top * 0.5, smoothstep(0.5, 0.62, d) * 0.7);
	float pupil = 1.0 - smoothstep(0.24, 0.28, d);
	vec3 col = vec3(0.97, 0.96, 1.0);
	col = mix(col, col * 0.78, smoothstep(top - 0.3, top, p.y) * 0.8);
	col = mix(col, iris_col, iris);
	col = mix(col, vec3(0.04, 0.02, 0.08), pupil * iris);
	float h1 = circle(p, c + vec2(-0.2, 0.28), 0.17, 0.03);
	float h2 = circle(p, c + vec2(0.22, -0.3), 0.08, 0.03);
	col = mix(col, vec3(1.0), clamp(h1 + h2, 0.0, 1.0));
	float lash = smoothstep(top - 0.16 - 0.1 * max(p.x, 0.0), top - 0.1 - 0.1 * max(p.x, 0.0), p.y);
	col = mix(col, lash_color, lash);
	float low = 1.0 - smoothstep(bot + 0.03, bot + 0.09, p.y);
	col = mix(col, lash_color, low * 0.55);
	ALBEDO = col;
	ALPHA = inside;
}
