extends CharacterBody3D

# Customer States
enum State {
	SHOPPING,
	GOING_TO_CHECKOUT,
	WAITING_AT_CHECKOUT,
	LEAVING
}

# Movement Settings
@export_group("Movement")
@export var speed: float = 2.0
@export var shopping_loops: int = 2  # How many times to loop the shopping path

# Checkout Settings
@export_group("Checkout")
@export var wait_time_at_checkout: float = 5.0
@export var customer_marker_path: NodePath  # Where customer stands at checkout

# Internal State
var path_follow: PathFollow3D
var current_state: State = State.SHOPPING
var customer_marker: Node3D
var wait_timer: float = 0.0
var completed_loops: int = 0

func _ready():
	# Get the PathFollow3D parent
	path_follow = get_parent()
	if not path_follow is PathFollow3D:
		push_error("AICustomer must be a child of PathFollow3D")
		return
	
	# Find the customer checkout marker
	if customer_marker_path:
		customer_marker = get_node(customer_marker_path)
	else:
		customer_marker = get_tree().root.find_child("CustomerBuyingMarker", true, false)
	
	if customer_marker:
		print("Customer ready. Checkout marker found at: ", customer_marker.get_path())
	else:
		print("WARNING: Could not find customer checkout marker!")

func _physics_process(delta):
	match current_state:
		State.SHOPPING:
			_shopping(delta)
		State.GOING_TO_CHECKOUT:
			_going_to_checkout(delta)
		State.WAITING_AT_CHECKOUT:
			_waiting_at_checkout(delta)
		State.LEAVING:
			_leaving(delta)

# STATE: Shopping - Move along the path
func _shopping(delta):
	# Move along the shopping path
	path_follow.progress += speed * delta
	
	# Check if completed a loop
	if path_follow.progress_ratio >= 1.0:
		completed_loops += 1
		path_follow.progress_ratio = 0.0
		print("Completed shopping loop ", completed_loops, "/", shopping_loops)
		
		# Done shopping, go to checkout
		if completed_loops >= shopping_loops:
			current_state = State.GOING_TO_CHECKOUT
			print("Done shopping. Heading to checkout.")

# STATE: Going to Checkout - Walk to checkout marker
func _going_to_checkout(_delta):
	if not customer_marker:
		# No marker found, just wait in place
		current_state = State.WAITING_AT_CHECKOUT
		return
	
	# Calculate direction to checkout marker
	var target_pos = customer_marker.global_position
	target_pos.y = global_position.y  # Keep at same height
	
	var direction = (target_pos - global_position).normalized()
	direction.y = 0
	
	# Move toward checkout
	velocity = direction * speed
	move_and_slide()
	
	# Check if arrived at checkout
	var distance = Vector2(global_position.x, global_position.z).distance_to(
		Vector2(target_pos.x, target_pos.z)
	)
	
	if distance < 0.5:
		velocity = Vector3.ZERO
		current_state = State.WAITING_AT_CHECKOUT
		wait_timer = 0.0
		print("Arrived at checkout. Waiting...")

# STATE: Waiting at Checkout - Stand still and wait
func _waiting_at_checkout(delta):
	velocity = Vector3.ZERO
	wait_timer += delta
	
	if wait_timer >= wait_time_at_checkout:
		current_state = State.LEAVING
		print("Done at checkout. Leaving store...")

# STATE: Leaving - Walk away and despawn
func _leaving(_delta):
	# Move forward (positive Z direction)
	velocity = Vector3(0, 0, 1) * speed
	move_and_slide()
	
	# Remove customer when far enough away
	if global_position.z > 10:
		print("Customer left the store.")
		queue_free()
