shader_type spatial;
render_mode blend_mix, cull_front, unshaded;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color;
uniform bool use_base_texture = false;
uniform float size : hint_range(1.0, 1.5, 0.01) = 1.05;

void vertex() {
	VERTEX *= size;
}

void fragment() {
	vec3 object_color = base_color.rgb;
	if (use_base_texture) {
		object_color *= texture(base_texture, UV).rgb;
	}
	ALBEDO = vec3(1.0) - object_color;
	ALPHA = 1.0;
}
