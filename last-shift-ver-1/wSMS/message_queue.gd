class_name MessageQueue
extends Control

@export_subgroup("Resource Folders")
@export var image_directory: String = "res://wSMS/resources/images/"
@export var script_directory: String = "res://wSMS/resources/scripts/"
@export_subgroup("Widget Scenes")
## Skin for text message
@export var text_scene: PackedScene
## Skin for image message
@export var img_scene: PackedScene
## Skin for choice button
@export var choice_button_scene: PackedScene

@export_subgroup("Textbox Options")
## Cap the amount of held message objects
@export var cap_max_messages: bool = false
## Edit this depending on the phone size, won't work if it's higher than node size
@export var max_messages: int = 1
## How many chars long a textbox line can be, sets static property of TextBox
@export var char_width_of_box: int = 28
## Time between messages (decimal of a second)
@export var time_between_messages: float = 1

@export_subgroup("Misc. positioning")
## How far over the player's messages are
@export var slide_to_the_right: float = 120.0
## Move the entire nodeset over when "move_offset()" is called
@export var offset: Vector2 = Vector2(0,0)
## Alter location of choicebox in relation to main message queue (applied as well as general offset)
@export var choices_offset: Vector2 = Vector2(0,0)


var message_queue: Array[TextBox]
var if_stack: Array[bool] = []
## Player chooicebox has now appeared
signal started_choosing
## Player has selected a choicebox
signal done_choosing
## A scene has finished playing, includes recursive calls from choice boxes etc
signal done_scene
## A played scene has finished playing, returns the given name
signal done_named_scene(scene_name: String)
## A scene has started playing, sends out the scene's name
signal started_scene(name: String)

@onready var choice_box: ChoiceSelect = $ChoiceSelect; 
var choosing = false; var choice_box_y: int;


func _ready(): 
	$ChoiceSelect.slide(slide_to_the_right)
	$VBox.size = size
	$VBox.position += Vector2(20, -$VBox.get_theme_constant("separation")*6)
	choice_box_y = $VBox.position.y+(5)*$VBox.get_theme_constant("separation")
	TextBox.max_chars = char_width_of_box
	
	$ChoiceSelect.choice_button_scene = choice_button_scene

## Load a file (starts from script directory)
func load_file(file_name: String):
	#$Variables.clear()
	var n: String = script_directory+file_name
	$Scenes.load_file(n)

## Move over to the given offset position
func move_offset(): 
	$VBox.position += offset
	choice_box_y = $VBox.position.y+(5)*$VBox.get_theme_constant("separation")

###########
# Testing #
###########

## Load the test script
func run_test(): 
	load_file("test_forgame.txt")
	await play_from_scene("choicescene")

## Blocking function for playing from a set starting point at a scene
func play_from_scene(scene_name: String): 
	goto(scene_name)
	#await done_scene

################
# Initialisers #
################

# Decode string array into a stringlist
# FLAGS:
# player's msg = "&"
# image = ":"
# See variable script for more detail on:
# var = "&"
# expression = "{stuff}"
## Parses an array of strings into their respective commands. See comment for flags
func add_multi(lots: Array[String]):
	for ia: String in lots:
		var i = ia.strip_escapes()
		#print(i)
		# Check if choice is being parsed
		if i.begins_with("#choice") || choosing:
			await _parse_choice(i)
			continue
		
		# Check if conditional is present, and if this statement fits
		if !_should_read() and !i.begins_with("#e"): continue
		# If empty somehow, yeet out
		if i == "": continue
		
		# Redirects for non-message input
		# Can't use match here unfortunately
		if i.begins_with("#go"): # Scene change
			goto(i)
			return
		
		if i.begins_with("#if") || i.begins_with("#e"): # Conditionals
			_parse_if(i)
			continue
		
		if i.begins_with("{"): # Hidden expression
			$Variables.read_var(i)
			continue
		
		# Strip flags and make a new message
		var left_side = !i.begins_with("&")
		var new_i = i.trim_prefix("&") # remove redundancy characters
		# For notation cases
		if new_i.begins_with(":"):
			new_image(new_i.erase(0, 1))
		else: new_message(new_i, left_side)
		
		await get_tree().create_timer(time_between_messages/2.0).timeout
	done_scene.emit()

## Play a named scene stored in the scenes sub-node, emits a named signal on completion
func _play_scene(lines: PackedStringArray, scene_name: String):
	await add_multi(lines)
	done_named_scene.emit(scene_name)

## Go to a file or another scene, starts from script directory
func goto(scene_name: String):
	if scene_name.begins_with("#"):
		await _parse_goto_function(scene_name)
	else:
		started_scene.emit(scene_name)
		await $Scenes.play_scene(scene_name)

func _parse_goto_function(cmd: String):
	# Go scene
	if cmd.begins_with("#goto"):
		var j = cmd.trim_prefix("#goto ")
		started_scene.emit(j)
		$Scenes.play_scene(j)
		return
	
	# Go file
	var i = cmd.trim_prefix("#gofile ")
	var args = i.split(" #to ")
	load_file(args[0].strip_escapes())
	goto("#goto "+args[1])


###########
# Parsers #
###########

## Parse a conditional expression
func _parse_if(statem: String):
	# Elements of argument
	var has_express: bool = statem.find(" ") != -1
	var command: String = statem.left(statem.find(" ")) # Command is before first space
	if !has_express: command = statem
	var expression: String = statem.trim_prefix(command+" ")
	
	var top_idx: int
	var top: bool
	
	# Current effective predicate
	if if_stack.size()>0:
		top_idx = if_stack.size()-1
		top = if_stack[top_idx]
	
	# 'else' flips the top predicate, no expression
	#print(command)
	match command:
		"#else": 
			if_stack[top_idx] = !top; 
			return # Theoretically you could have multiple elses wuh oh
		"#if": 
			if_stack.append($Variables._parse_expr(expression)); return
		"#endif": if_stack.remove_at(top_idx); return
		"#endelse": if_stack.remove_at(top_idx); return
		
		# On elif, replace the top condition if the previous condition has not already been read
		"#elif":
			if top: return
			if_stack[top_idx] = $Variables._parse_expr(expression)
		_:
			assert(false, "Command "+command+" not recognised")

## Returns if the next statement satisfies the current predicate
func _should_read()->bool:
	if if_stack.is_empty(): return true
	return if_stack[if_stack.size()-1]

## Parse a choice line, executing any relevant commands
func _parse_choice(text: String):
	match text.split(" ")[0]:
		"#choice":
			choosing = true
			choice_box.show()
			return
			
		"#endchoice":
			choice_box.position.y = choice_box_y-(3-choice_box.choice_amnt)*$VBox.get_theme_constant("separation")
			choice_box.position += choices_offset
			# Wait for response
			started_choosing.emit()
			var lines: PackedStringArray = await choice_box.add_to_stack
			choice_box.hide()
			await _run_subset(lines)
			return
		_:
			choice_box.parse_line(text)


################
# Add elements #
################

## Add a given TextBox object to the queue
func add_to_queue(box: TextBox):
	$VBox.add_child(box)
	box.force_resize()
	message_queue.append(box)
	box.force_resize()
	$VBox.hide(); $VBox.show()
	
	_shift_up()

## Add a text message, specify owner
func new_message(text: String, is_you: bool):
	var new_text: TextBox = text_scene.instantiate()
	new_text.setup($Variables.format_string(text), is_you)
	new_text.max_chars = char_width_of_box
	# Slide over if needed
	if !is_you:
		new_text.slide(int(slide_to_the_right))
	add_to_queue(new_text)

## Add an image message, always belongs to other
func new_image(path: String):
	var new_text: TextBox = img_scene.instantiate()
	new_text.setup(image_directory+path, true)
	add_to_queue(new_text)

## Run all commands from a child object
func _run_subset(lines: PackedStringArray):
	choosing = false
	await add_multi(lines)
	done_choosing.emit()

#################
# Move Controls #
#################

## Remove message elements that go past bounds, ignore is disabled
func _shift_up():
	if !cap_max_messages: return
	await get_tree().create_timer(time_between_messages/2.0).timeout
	while message_queue.size()>=max_messages: _rmv()

## Pop first element and return
func pop()->TextBox:
	var obj: TextBox = message_queue[0]
	message_queue.remove_at(0)
	$VBox.remove_child(obj)
	return obj

## Remove first element and free object
func _rmv(): 
	var a = pop(); a.queue_free()
	$VBox.hide(); $VBox.show() # Refresh the display (it gets mad)
