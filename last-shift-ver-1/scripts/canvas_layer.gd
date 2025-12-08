extends CanvasLayer
# Put this on any UI you want to be crisp and unaffected by shaders

func _ready() -> void:
	# Set layer above the pixelator (which is at 50)
	layer = 101
	
	# Ensure text filtering is sharp
	_set_texture_filter_recursive(self)

func _set_texture_filter_recursive(node: Node) -> void:
	# Make sure all Control nodes use nearest neighbor filtering for crisp text
	if node is Control:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	
	for child in node.get_children():
		_set_texture_filter_recursive(child)
