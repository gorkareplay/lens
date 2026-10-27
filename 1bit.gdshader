shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

uniform vec4 color_a : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec3 pixel = texture(screen_tex, SCREEN_UV).rgb;

    float dist_a = distance(pixel, color_a.rgb);
    float dist_b = distance(pixel, color_b.rgb);

    COLOR = vec4(dist_a < dist_b ? color_a.rgb : color_b.rgb, 1.0);
}