class_name ChoiceButton
extends TextBox

signal clicked(id: int)

var id_num: int = -1

#func _ready():
#	setup("hihijfslifjeslirjseilrjeslirjsleijerliser", 0)

#Overrides
func setup(text: String, is_you: bool):
	$Message.setup(text, is_you)

func force_resize(): 
	$Message.force_resize()
	$Button.size = $Message/Box.size
	$Button.position.x = $Message/Box.position.x
	size = $Message.size
	custom_minimum_size = $Message.size

func height()->float: return $Message/Box/Label.size.y

func slide(x_change: int):
	slide_amnt += x_change
	$Message.slide(x_change)
	force_resize()

# Unique
func attach_id(id: int): id_num = id
func _on_pressed() -> void: clicked.emit(id_num)
