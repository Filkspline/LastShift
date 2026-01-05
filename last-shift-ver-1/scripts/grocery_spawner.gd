extends Node3D

# Spawner settings
@export var spawn_interval: float = 2.0  # Seconds between spawns
@export var spawn_height: float = 0.5  # Height above spawner to spawn items
@export var spawn_radius: float = 0.01  # Random offset from center
@export var max_items: int = 4  # Maximum items before stopping spawn

# References
@export var grocery_item_scene: PackedScene

var spawn_timer: Timer
var item_count: int = 0
var spawned_items: Array = []  # Track all spawned items

func _ready():
	# Create and setup timer
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	print("Grocery spawner ready!")

func _on_spawn_timer_timeout():
	if item_count >= max_items:
		print("Max items reached, stopping spawner")
		spawn_timer.stop()
		return
	
	spawn_item()

func spawn_item():
	if not grocery_item_scene:
		print("Error: grocery_item_scene not assigned!")
		return
	
	# Create new item instance
	var item = grocery_item_scene.instantiate()
	
	# Add as child of spawner (they'll be reparented later)
	add_child(item)
	spawned_items.append(item)
	
	# Random spawn position with slight offset
	var random_offset = Vector3(
		randf_range(-spawn_radius, spawn_radius),
		0,
		randf_range(-spawn_radius, spawn_radius)
	)
	item.position = Vector3(0, spawn_height, 0) + random_offset
	
	
	item_count += 1
	print("Spawned item #", item_count)

func get_all_items() -> Array:
	"""Return all spawned items"""
	return spawned_items

func is_full() -> bool:
	return item_count >= max_items
