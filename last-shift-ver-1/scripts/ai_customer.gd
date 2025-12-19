extends CharacterBody3D

@export var speed: float = 2.0
@export var loop_path: bool = true

var path_follow: PathFollow3D

func _ready():
	path_follow = get_parent()
	if not path_follow is PathFollow3D:
		push_error("AICustomer must be a child of PathFollow3D")

func _physics_process(delta):
	if not path_follow:
		return
	
	# Move along the path
	path_follow.progress += speed * delta
	
	# Loop or stop at end
	if path_follow.progress_ratio >= 1.0:
		if loop_path:
			path_follow.progress_ratio = 0.0
		else:
			# Customer reached end of path
			queue_free()  # Remove customer
