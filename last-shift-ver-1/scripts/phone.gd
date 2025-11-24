extends Control

var is_expanded: bool = false
var rest_position: Vector2
var rest_rotation: float = 15.0
var rest_scale: Vector2 = Vector2(0.7, 0.7)

var center_position: Vector2
var center_rotation: float = 0.0
var center_scale: Vector2 = Vector2(1.0, 1.0)

var tween: Tween

func _ready():
	# Calculate positions
	var viewport_size = get_viewport_rect().size
	rest_position = Vector2(viewport_size.x - 150, viewport_size.y - 300)
	center_position = (viewport_size - custom_minimum_size) / 2
	
	# Set initial state
	position = rest_position
	rotation_degrees = rest_rotation
	scale = rest_scale
	pivot_offset = custom_minimum_size / 2
	
	# Connect button
	var button = $ClickArea
	button.pressed.connect(_on_phone_clicked)
	
	print("Phone initialized at: ", position)

func _on_phone_clicked():
	if is_expanded:
		collapse()
	else:
		expand()

func expand():
	is_expanded = true
	print("Expanding to center: ", center_position)
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(self, "position", center_position, 0.5)
	tween.tween_property(self, "rotation_degrees", center_rotation, 0.5)
	tween.tween_property(self, "scale", center_scale, 0.5)

func collapse():
	is_expanded = false
	print("Collapsing to corner: ", rest_position)
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(self, "position", rest_position, 0.4)
	tween.tween_property(self, "rotation_degrees", rest_rotation, 0.4)
	tween.tween_property(self, "scale", rest_scale, 0.4)
