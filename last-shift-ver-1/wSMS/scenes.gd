class_name Scenes
extends Node

signal play_from(lines: PackedStringArray, scene_name: String)

var scenes: Dictionary[String, PackedStringArray]

#func _ready():
#	load_file("res://test_forgame.txt")
#	print(scenes)

func load_file(string_name: String):
	scenes.clear()
	var whole_thing: String = FileAccess.open(string_name, FileAccess.READ).get_as_text()
	var scenes_unnamed = whole_thing.split("#endscene")
	for i in scenes_unnamed:
		var scene_name = i.left(i.find("##")).lstrip("\r\n").trim_prefix("#scene ")
		scenes[scene_name] = i.split("\n")
		
		# Remove pure whitespace
		var this_scene: PackedStringArray = scenes[scene_name]
		var j: int = 0; var max_line = this_scene.size()-1
		while j <= max_line:
			if this_scene[j] == "":
				this_scene.remove_at(j)
				max_line -= 1
				continue
			j+=1
		
		scenes[scene_name].remove_at(0)
	
	#print(scenes)

func play_scene(string_name: String):
	assert (scenes.keys().has(string_name), "Scene "+string_name+" does not exist in "+str(scenes.keys()))
	play_from.emit(scenes[string_name], string_name)
