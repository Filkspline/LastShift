extends RigidBody3D

# Drag settings
@export var max_drag_speed: float = 4.0  # Maximum speed before line breaks
@export var drag_strength: float = 6.0   # How strongly item follows mouse
@export var line_break_distance: float = 1.5  # Maximum distance before line breaks
@export var damping: float = 0.2  # Lower = more momentum

# State
var is_dragging: bool = false
var mouse_world_position: Vector3
var camera: Camera3D
var last_position: Vector3
var current_velocity: float = 0.0

# Line rendering
var line_mesh: ImmediateMesh
var line_material: StandardMaterial3D

func _ready():
	# Find the camera
	camera = get_viewport().get_camera_3d()
	
	# Setup line rendering
	setup_line()
	
	# Store initial position
	last_position = global_position
	
	# Enable mouse input
	input_ray_pickable = true
	
	# Set damping for momentum feel
	linear_damp = damping
	angular_damp = 1.0

func setup_line():
	var line_node = $Line3D
	
	# Make line render above everything else
	line_node.top_level = true
	line_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Create immediate mesh for dynamic line
	line_mesh = ImmediateMesh.new()
	line_node.mesh = line_mesh
	
	# Create material for line - thicker and more visible
	line_material = StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = Color(1, 1, 1, 1.0)
	line_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	line_material.no_depth_test = true  # Render on top - this is critical
	line_material.render_priority = 10  # Render last
	line_node.material_override = line_material
	line_node.sorting_offset = 100.0  # Force it to render on top

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check if mouse is over this object
				var mouse_pos = event.position
				var from = camera.project_ray_origin(mouse_pos)
				var to = from + camera.project_ray_normal(mouse_pos) * 1000
				
				var space_state = get_world_3d().direct_space_state
				var query = PhysicsRayQueryParameters3D.create(from, to)
				var result = space_state.intersect_ray(query)
				
				if result and result.collider == self:
					start_drag()
			else:
				stop_drag()

func start_drag():
	is_dragging = true
	gravity_scale = 0.0
	# Don't zero velocity - let it keep momentum
	angular_velocity = Vector3.ZERO
	last_position = global_position
	linear_damp = damping * 2.0  # Slightly more damping while dragging
	print("Started dragging item")

func stop_drag():
	is_dragging = false
	gravity_scale = 2.0
	linear_damp = damping  # Back to normal damping
	print("Stopped dragging item")

func _physics_process(delta):
	if is_dragging:
		update_mouse_world_position()
		
		# Calculate velocity
		var position_delta = global_position - last_position
		current_velocity = position_delta.length() / delta
		last_position = global_position
		
		# Check if moving too fast
		if current_velocity > max_drag_speed:
			break_line()
			return
		
		# Check if too far from mouse
		var distance_to_mouse = global_position.distance_to(mouse_world_position)
		if distance_to_mouse > line_break_distance:
			break_line()
			return
		
		# Apply force toward mouse position
		var direction = (mouse_world_position - global_position)
		var force = direction * drag_strength
		apply_central_force(force)
		
		# Update line color based on speed
		update_line_color()
	
	# Draw line
	draw_line()

func update_mouse_world_position():
	if not camera:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var normal = camera.project_ray_normal(mouse_pos)
	
	# Project onto XY plane (Z = item's current Z position)
	var plane = Plane(Vector3(0, 0, 1), global_position.z)
	var intersection = plane.intersects_ray(from, normal)
	
	if intersection:
		mouse_world_position = intersection

func update_line_color():
	# Color changes from white to yellow to red as speed increases
	var speed_ratio = clamp(current_velocity / max_drag_speed, 0.0, 1.0)
	
	if speed_ratio < 0.5:
		# White to yellow
		var t = speed_ratio * 2.0
		line_material.albedo_color = Color(1, 1, 1 - t * 0.5, 1.0)
	else:
		# Yellow to red
		var t = (speed_ratio - 0.5) * 2.0
		line_material.albedo_color = Color(1, 1 - t, 0, 1.0)

func draw_line():
	line_mesh.clear_surfaces()
	
	if is_dragging:
		# Update line position to follow item
		$Line3D.global_position = global_position
		
		# Draw thicker line using triangles instead of primitive lines
		var start = Vector3.ZERO
		var end = to_local(mouse_world_position)
		var thickness = 0.03
		
		# Calculate perpendicular vector for thickness
		var direction = (end - start).normalized()
		var perpendicular = Vector3(-direction.y, direction.x, 0) * thickness
		
		line_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		
		# First triangle
		line_mesh.surface_add_vertex(start + perpendicular)
		line_mesh.surface_add_vertex(start - perpendicular)
		line_mesh.surface_add_vertex(end + perpendicular)
		
		# Second triangle
		line_mesh.surface_add_vertex(end + perpendicular)
		line_mesh.surface_add_vertex(start - perpendicular)
		line_mesh.surface_add_vertex(end - perpendicular)
		
		line_mesh.surface_end()

func break_line():
	print("Line broke! Speed: ", current_velocity)
	stop_drag()
	
	# Add a little impulse away from mouse
	var direction = (global_position - mouse_world_position).normalized()
	apply_central_impulse(direction * 2.0)
