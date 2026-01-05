extends RigidBody3D

# Drag Settings
@export_group("Drag Behavior")
@export var drag_strength: float = 6.0
@export var max_drag_speed: float = 4.0
@export var line_break_distance: float = 1.5

# Physics Settings
@export_group("Physics")
@export var drag_damping: float = 0.4
@export var rotation_damping: float = 0.8

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
	camera = get_viewport().get_camera_3d()
	setup_line()
	last_position = global_position
	input_ray_pickable = true
	
	# Simple physics setup
	linear_damp = drag_damping
	angular_damp = rotation_damping
	continuous_cd = true

func setup_line():
	var line_node = $Line3D
	line_node.top_level = true
	line_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	line_mesh = ImmediateMesh.new()
	line_node.mesh = line_mesh
	
	line_material = StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = Color(1, 1, 1, 1.0)
	line_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	line_material.no_depth_test = true
	line_material.render_priority = 10
	line_node.material_override = line_material
	line_node.sorting_offset = 100.0

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_pos = event.position
			var from = camera.project_ray_origin(mouse_pos)
			var to = from + camera.project_ray_normal(mouse_pos) * 1000
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from, to)
			query.collision_mask = 4  # Layer 3
			
			var result = space_state.intersect_ray(query)
			if result and result.collider == self:
				start_drag()
		else:
			stop_drag()

func start_drag():
	is_dragging = true
	gravity_scale = 0.0
	last_position = global_position

func stop_drag():
	is_dragging = false
	gravity_scale = 0.5
	
	# Limit velocity on release
	if linear_velocity.length() > 3.0:
		linear_velocity = linear_velocity.normalized() * 3.0

func _physics_process(delta):
	# Constrain Z axis and rotation when not dragging
	if not is_dragging:
		var vel = linear_velocity
		vel.z = 0
		linear_velocity = vel
		
		var ang_vel = angular_velocity
		ang_vel.x = 0
		ang_vel.y = 0
		angular_velocity = ang_vel
	
	if is_dragging:
		update_mouse_world_position()
		
		# Calculate current velocity
		var position_delta = global_position - last_position
		current_velocity = position_delta.length() / delta
		last_position = global_position
		
		# Break line if too fast or too far
		if current_velocity > max_drag_speed or global_position.distance_to(mouse_world_position) > line_break_distance:
			stop_drag()
			return
		
		# Pull item toward mouse
		var direction = (mouse_world_position - global_position)
		apply_central_force(direction * drag_strength)
		
		update_line_color()
	
	draw_line()

func update_mouse_world_position():
	if not camera:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var normal = camera.project_ray_normal(mouse_pos)
	
	# Project onto XY plane at item's Z position
	var plane = Plane(Vector3(0, 0, 1), global_position.z)
	var intersection = plane.intersects_ray(from, normal)
	
	if intersection:
		mouse_world_position = intersection

func update_line_color():
	var speed_ratio = clamp(current_velocity / max_drag_speed, 0.0, 1.0)
	
	if speed_ratio < 0.5:
		var t = speed_ratio * 2.0
		line_material.albedo_color = Color(1, 1, 1 - t * 0.5, 1.0)
	else:
		var t = (speed_ratio - 0.5) * 2.0
		line_material.albedo_color = Color(1, 1 - t, 0, 1.0)

func draw_line():
	line_mesh.clear_surfaces()
	
	if is_dragging:
		var line_node = $Line3D
		line_node.global_position = global_position
		line_node.global_rotation = Vector3.ZERO
		
		var start = Vector3.ZERO
		var end = mouse_world_position - global_position
		var thickness = 0.03
		
		var direction = (end - start).normalized()
		var perpendicular = Vector3(-direction.y, direction.x, 0) * thickness
		
		line_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		
		# Main line
		line_mesh.surface_add_vertex(start + perpendicular)
		line_mesh.surface_add_vertex(start - perpendicular)
		line_mesh.surface_add_vertex(end + perpendicular)
		
		line_mesh.surface_add_vertex(end + perpendicular)
		line_mesh.surface_add_vertex(start - perpendicular)
		line_mesh.surface_add_vertex(end - perpendicular)
		
		# Rounded caps
		draw_circle_cap(start, perpendicular, 8)
		draw_circle_cap(end, perpendicular, 8)
		
		line_mesh.surface_end()

func draw_circle_cap(center: Vector3, perpendicular: Vector3, segments: int):
	var radius = perpendicular.length()
	var angle_step = PI * 2.0 / segments
	
	for i in range(segments):
		var angle1 = i * angle_step
		var angle2 = (i + 1) * angle_step
		
		var point1 = center + Vector3(cos(angle1), sin(angle1), 0) * radius
		var point2 = center + Vector3(cos(angle2), sin(angle2), 0) * radius
		
		line_mesh.surface_add_vertex(center)
		line_mesh.surface_add_vertex(point1)
		line_mesh.surface_add_vertex(point2)
