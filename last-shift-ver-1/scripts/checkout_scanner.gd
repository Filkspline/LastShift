extends Area3D

# Track which items have been scanned to avoid duplicate scans
var scanned_items: Array = []

func _ready():
	# Signals are already connected in the scene file, so we don't need to connect them again
	# Just print that we're ready
	print("Checkout scanner ready!")

func _on_body_entered(body: Node3D):
	# Check if it's a grocery item (works with both placed and spawned items)
	if body is RigidBody3D and (body.is_in_group("grocery_item") or body.name.contains("GroceryItem") or body.has_method("start_drag")):
		# Check if we haven't already scanned this item
		if not scanned_items.has(body):
			scan_item(body)
			scanned_items.append(body)

func _on_body_exited(body: Node3D):
	# Remove from scanned items when it leaves the scan area
	if scanned_items.has(body):
		scanned_items.erase(body)

func scan_item(item: Node3D):
	print("🔔 ITEM SCANNED: ", item.name)
	
	# Optional: Add visual/audio feedback here
	# You could flash the scanner color, play a beep sound, etc.
	flash_scanner()

func flash_scanner():
	# Visual feedback - flash green briefly
	var mesh = get_parent().get_node("ScannerMesh")
	var material = mesh.get_active_material(0)
	
	if material:
		var original_color = material.albedo_color
		material.albedo_color = Color(0, 1, 0, 1)  # Green flash
		
		# Reset color after 0.2 seconds
		await get_tree().create_timer(0.2).timeout
		material.albedo_color = original_color
