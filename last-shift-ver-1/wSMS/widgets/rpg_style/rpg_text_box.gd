class_name RpgTextBox
extends TextBox

func _ready(): max_chars = 23

func setup(text: String, is_you: bool):
	assert(!_is_setup, "Cannot set up multiple times")
	self.is_you = is_you
	
	# Display
	$Box.size.y = 0
	$Box/Label.text = format_text(text)
	
	# Setting up variables
	size = $Box/Label.size
	custom_minimum_size = size
	chars = text.length() if text.length()<= max_chars else max_chars
	$Box/Label.add_theme_font_size_override("normal_font_size", font_size)

func _clipped_pos()->float: return position.x - $Box.size.x-16
func slide(x_change: int): slide_amnt = x_change
