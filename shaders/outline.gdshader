shader_type spatial;
render_mode unshaded, cull_front;

uniform float thickness = 0.0045;
uniform vec3 outline_color : source_color = vec3(0.07, 0.04, 0.12);

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color;
}
