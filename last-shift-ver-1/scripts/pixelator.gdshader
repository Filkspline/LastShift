// pixelator.gdshader
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 16.0) = 3.0;
uniform vec2 screen_size = vec2(1152.0, 648.0);

void fragment() {
	// Calculate pixelated coordinates
	vec2 screen_coord = SCREEN_UV * screen_size;
	vec2 pixelated_coord = floor(screen_coord / pixel_size) * pixel_size;
	vec2 pixelated_uv = pixelated_coord / screen_size;

	// Sample the screen texture at pixelated coordinates
	vec4 color = texture(SCREEN_TEXTURE, pixelated_uv);

	COLOR = color;
}