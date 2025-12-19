class_name TextBox
extends Control

# vars u can get
static var max_chars: int = 28
const WIDTH: int = 240 # for outside reference

@export var you_colour: Color = Color(0.569, 0.569, 0.569)
@export var me_colour: Color = Color(0.569, 0.569, 0.569)
@export var font_size: int = 16
var is_you: bool = false
var _is_setup: bool = false
var chars: int; var slide_amnt: int = 0


func setup(text: String, is_you: bool):
	assert(!_is_setup, "Cannot set up multiple times")
	self.is_you = is_you
	
	# Display
	$Box.size.y = 0
	$Box/Label.text = format_text(text)
	if is_you: 
		$Tail/TailMe.hide()
	else: 
		$Tail/TailYou.hide()
		$Box/Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_is_setup = true
	_change_colour()
	
	# Setting up variables
	size = $Box/Label.size
	custom_minimum_size = size
	chars = text.length() if text.length()<= max_chars else max_chars
	$Box/Label.add_theme_font_size_override("normal_font_size", font_size)

## Won't split a word but splits words over to new-line if needed
func format_text(text: String)->String:
	if text.length()<max_chars: return text
	
	var splitted_truly: PackedStringArray = text.split(" ")
	var counter: int = 0; 
	var i: int = -1
	var last_idx: int = splitted_truly.size() - 1
	
	# Word splitter
	var word: String
	while i < last_idx:
		i+=1
		word = splitted_truly[i]
		# Word too long, split into pieces and leave room for recurse
		if word.length() >= max_chars:
			var left_str: String = word.left(max_chars-counter)
			var remainder: int = word.length()-(max_chars-counter)
			var right_str: String = word.right(remainder)
			splitted_truly[i] = left_str
			splitted_truly.insert(i+1, "\n"+right_str)
			last_idx += 1
			counter = 0
			continue
		
		# Word overflow
		if counter + word.length() >= max_chars or word == "\n":
			splitted_truly.insert(i, "\n")
			counter = 0
			continue
		counter+=word.length()
	return " ".join(splitted_truly)


################
# Other config #
################

## Force the the textbox object to fit around the inner label
func force_resize(): 
	clip_to_text()
	size.y = $Box/Label.size.y
	custom_minimum_size = size

## Yink over the box to fit the text because apparently this engine would combust if it let you do things easily
func clip_to_text():
	# Don't ask why this works
	$Box.custom_minimum_size.x = chars
	$Box.size.x = chars
	if !is_you:
		$Box.position.x = _clipped_pos()+slide_amnt

## yeet over to the side
func slide(x_change: int):
	$Tail.position.x += x_change
	slide_amnt = x_change

## X of box clipped to message
func _clipped_pos()->float: return $Tail/TailMe.position.x - $Box.size.x-16

## Change the colour of the textbox components
func _change_colour():
	var new_stylebox: StyleBoxFlat = $Box.get_theme_stylebox("panel").duplicate()
	if !is_you:
		$Tail/TailMe.color = me_colour
		new_stylebox.bg_color = me_colour
	else:
		$Tail/TailYou.color = you_colour
		new_stylebox.bg_color = you_colour
	$Box.add_theme_stylebox_override("panel", new_stylebox)
