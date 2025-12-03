extends CanvasLayer

@export var pixel_size: float = 3.0
@export var range_per_color: int = 8  # Color quantization range (2-32)
@export var enable_color_quantization: bool = true  # Toggle color reduction on/off

var color_rect: ColorRect
var shader_material: ShaderMaterial

func _ready() -> void:
	# Set layer to be on top
	layer = 100
	
	# Create ColorRect
	color_rect = ColorRect.new()
	add_child(color_rect)
	
	# Make it cover the whole screen
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0
	
	# Use nearest neighbor filtering for crisp pixels
	color_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Load and apply shader
	var shader = load("res://scripts/pixelator.gdshader")
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("pixel_size", pixel_size)
	shader_material.set_shader_parameter("range_per_color", range_per_color)
	shader_material.set_shader_parameter("enable_color_quantization", enable_color_quantization)
	
	# Get actual screen size
	var viewport_size = get_viewport().get_visible_rect().size
	shader_material.set_shader_parameter("screen_size", viewport_size)
	
	color_rect.material = shader_material
	
	# Don't block input
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_pixel_size(size: float) -> void:
	pixel_size = size
	if shader_material:
		shader_material.set_shader_parameter("pixel_size", pixel_size)

func set_range_per_color(range: int) -> void:
	range_per_color = clamp(range, 2, 32)
	if shader_material:
		shader_material.set_shader_parameter("range_per_color", range_per_color)

func set_color_quantization(enabled: bool) -> void:
	enable_color_quantization = enabled
	if shader_material:
		shader_material.set_shader_parameter("enable_color_quantization", enabled)

func _notification(what: int) -> void:
	# Update screen size on viewport resize
	if what == NOTIFICATION_WM_SIZE_CHANGED and shader_material:
		var viewport_size = get_viewport().get_visible_rect().size
		shader_material.set_shader_parameter("screen_size", viewport_size)
