extends Control

@onready var queue = $MessageQueue

func _ready(): 
	var choicebox: ChoiceSelect = $MessageQueue/ChoiceSelect
	choicebox.echo_choice_names = false
	
	
	queue.load_file("npc_dialogue_test.txt")
	queue.play_from_scene("a")
