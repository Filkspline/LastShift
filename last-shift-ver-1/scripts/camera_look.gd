extends Camera3D

@export var look_sensitivity: float = 15.0
@export var max_angle: float = 10.0

var mouse_position: Vector2 = Vector2.ZERO
var viewport_size: Vector2

func _ready():
	viewport_size = get_viewport().get_visible_rect().size

func _process(delta):
	# Get mouse position relative to screen center
	mouse_position = get_viewport().get_mouse_position()
	var center = viewport_size / 2.0
	var offset = (mouse_position - center) / center
	
	# Clamp the offset
	offset = offset.clamp(Vector2(-1, -1), Vector2(1, 1))
	
	# Calculate target rotation based on mouse position
	var target_x = -offset.y * max_angle
	var target_y = -offset.x * max_angle  # Fixed: added negative sign
	
	# Smoothly interpolate rotation
	rotation_degrees.x = lerp(rotation_degrees.x, target_x, look_sensitivity * delta)
	rotation_degrees.y = lerp(rotation_degrees.y, target_y, look_sensitivity * delta)
