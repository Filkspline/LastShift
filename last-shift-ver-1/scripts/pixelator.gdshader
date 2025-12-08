// pixelator.gdshader - Combined pixelation and color quantization
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 16.0) = 2.0;
uniform vec2 screen_size = vec2(1152.0, 648.0);
uniform int range_per_color : hint_range(2, 32) = 8;
uniform bool enable_color_quantization = true;

void fragment() {
	// Calculate pixelated coordinates
	vec2 screen_coord = SCREEN_UV * screen_size;
	vec2 pixelated_coord = floor(screen_coord / pixel_size) * pixel_size;
	vec2 pixelated_uv = pixelated_coord / screen_size;
	
	// Sample the screen texture at pixelated coordinates
	vec4 original_color = texture(SCREEN_TEXTURE, pixelated_uv);
	
	// Apply color quantization if enabled
	if (enable_color_quantization) {
		// Quantize colors to create indexed color effect
		float new_r = original_color.r * float(range_per_color);
		new_r = round(new_r) / float(range_per_color);
		
		float new_g = original_color.g * float(range_per_color);
		new_g = round(new_g) / float(range_per_color);
		
		float new_b = original_color.b * float(range_per_color);
		new_b = round(new_b) / float(range_per_color);
		
		COLOR = vec4(new_r, new_g, new_b, original_color.a);
	} else {
		COLOR = original_color;
	}
}