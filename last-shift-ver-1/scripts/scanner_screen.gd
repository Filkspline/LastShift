extends Node3D

var total_price: float = 0.0
var item_list: VBoxContainer
var total_price_label: Label
var viewport: SubViewport
var display_mesh: MeshInstance3D

func _ready():
	# Get references to UI elements
	viewport = $SubViewport
	item_list = $SubViewport/ScreenUI/MarginContainer/VBoxContainer/ItemList
	total_price_label = $SubViewport/ScreenUI/MarginContainer/VBoxContainer/TotalContainer/TotalPrice
	display_mesh = $DisplayScreen
	
	# Make sure viewport renders continuously
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Create viewport texture and apply it to the display mesh
	var viewport_texture = viewport.get_texture()
	var material = StandardMaterial3D.new()
	material.albedo_texture = viewport_texture
	material.emission_enabled = true
	material.emission_texture = viewport_texture
	material.emission_energy_multiplier = 1.5
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	display_mesh.set_surface_override_material(0, material)
	
	print("Scanner screen ready!")

func add_scanned_item(item_name: String, price: float):
	# Create a new item entry
	var item_container = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = item_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2, 1))
	name_label.add_theme_font_size_override("font_size", 16)
	
	var price_label = Label.new()
	price_label.text = "$%.2f" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2, 1))
	price_label.add_theme_font_size_override("font_size", 16)
	
	item_container.add_child(name_label)
	item_container.add_child(price_label)
	
	# Add to the list
	item_list.add_child(item_container)
	
	# Update total
	total_price += price
	total_price_label.text = "$%.2f" % total_price
	
	# Flash effect
	flash_screen()
	
	# Keep only last 5 items visible
	if item_list.get_child_count() > 5:
		var oldest = item_list.get_child(0)
		item_list.remove_child(oldest)
		oldest.queue_free()

func flash_screen():
	# Brief flash effect
	var material = display_mesh.get_active_material(0) as StandardMaterial3D
	if material:
		var original_energy = material.emission_energy_multiplier
		material.emission_energy_multiplier = 3.0
		
		await get_tree().create_timer(0.1).timeout
		material.emission_energy_multiplier = original_energy

func clear_items():
	# Clear all items
	for child in item_list.get_children():
		item_list.remove_child(child)
		child.queue_free()
	
	total_price = 0.0
	total_price_label.text = "$0.00"
