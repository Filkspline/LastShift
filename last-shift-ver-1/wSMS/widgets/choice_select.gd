class_name ChoiceSelect
extends TextBox

@export_subgroup("Button options")
@export var choice_button_scene: PackedScene
@export var button_width: int
## Add the text name of the choice to the contained lines, adding the choice to the message queue
@export var echo_choice_names: bool = true

signal add_to_stack(lines: PackedStringArray)
var choices: Dictionary[int, PackedStringArray] = {}
var choice_amnt: int = 0

#func _ready():
#	parse_line("-> fervfew")
#	parse_line("-> wfqwef wrwoierjewoirw eww3rw3rw3")
#	parse_line("-> fervfew")

## Parse a script line, editing the structure
func parse_line(text: String):
	if text.begins_with("->"):
		var n = text.trim_prefix("-> ")
		var idx = choices.size()
		if echo_choice_names: choices[idx] = PackedStringArray(["&"+n])
		else: choices[idx] = PackedStringArray()
			
		_add_choice(n)
	else:
		choices[choices.size()-1].append(text)

## Add a new choice to the group
func _add_choice(text: String):
	choice_amnt+=1
	var choice: ChoiceButton = choice_button_scene.instantiate()
	choice.setup(text, false)
	choice.attach_id(choice_amnt-1)
	choice.connect("clicked", _option_selected)
	$Container.add_child(choice)
	choice.force_resize()
	choice.slide(slide_amnt-20)
	$Container.hide(); $Container.show()

## When an option is selected, send up the instructions and clear all boxes
func _option_selected(id: int): 
	add_to_stack.emit(choices[id])
	choices.clear()
	var boxes = $Container.get_children()
	var box: ChoiceButton
	while choice_amnt>0:
		box = boxes[choice_amnt-1]
		$Container.remove_child(box)
		boxes[choice_amnt-1].queue_free()
		choice_amnt-=1
	choice_amnt = 0


# Redundant override functions
func setup(text: String, is_you: bool):
	assert(false, "Use setup_choice()")
	pass

func force_resize(): 
	var heights: int = 0; var amnt = 0
	for i: ChoiceButton in $Container.get_children():
		i.force_resize()
		heights += i.height(); amnt+=1
	heights += $Container.get_theme_constant("separation")*(amnt+1)
	custom_minimum_size.y = heights

func slide(x_change: int):
	slide_amnt += x_change
