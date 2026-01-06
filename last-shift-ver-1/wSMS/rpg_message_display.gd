extends Control

@onready var queue = $Container/MessageQueue

# IF YOU WANT TO EDIT STUFF
# chars per line: rpg_text_box param max_chars
# size of container: container size + fiddle with messagequeue offset (sorry)
# font size: export var in rpg_text_box

func _ready(): 
	# Change settings of the message queue's internal stuff
	queue.choice_box.echo_choice_names = false
	$Container/MessageQueue/VBox.alignment = BoxContainer.AlignmentMode.ALIGNMENT_CENTER
	
	queue.move_offset()
	
	queue.load_file("npc_dialogue_test.txt")
	queue.play_from_scene("a")
