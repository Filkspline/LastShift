extends Area3D

# Track which items have been scanned to avoid duplicate scans
var scanned_items: Array = []
var scanner_screen: Node3D = null

func _ready():
	print("Checkout scanner ready!")
	# Find the scanner screen (will be added to the scene)
	call_deferred("find_scanner_screen")

func find_scanner_screen():
	# Look for the scanner screen in the parent or scene
	var parent = get_parent().get_parent()
	if parent:
		scanner_screen = parent.get_node_or_null("ScannerScreen")
		if scanner_screen:
			print("Scanner screen found and connected!")
		else:
			print("Warning: Scanner screen not found in scene!")

func _on_body_entered(body: Node3D):
	# Check if it's a grocery item
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
	# Generate a random price between $1.00 and $15.99
	var price = randf_range(1.0, 15.99)
	
	# Get item name
	var item_name = item.name
	
	print("🔔 ITEM SCANNED: %s - $%.2f" % [item_name, price])
	
	# Add to scanner screen if available
	if scanner_screen and scanner_screen.has_method("add_scanned_item"):
		scanner_screen.add_scanned_item(item_name, price)
	
	# Visual feedback
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
