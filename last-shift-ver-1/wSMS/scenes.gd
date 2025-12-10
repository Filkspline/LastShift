class_name Scenes
extends Node

signal play_from(lines: PackedStringArray)

var scenes: Dictionary[String, PackedStringArray]

#func _ready():
#	load_file("res://test_forgame.txt")
#	print(scenes)

func load_file(name: String):
	scenes.clear()
	var whole_thing: String = FileAccess.open(name, FileAccess.READ).get_as_text()
	var scenes_unnamed = whole_thing.split("#endscene")
	for i in scenes_unnamed:
		var scene_name = i.left(i.find("##")).lstrip("\r\n").trim_prefix("#scene ")
		scenes[scene_name] = i.split("\n")
		
		# Remove pure whitespace
		var to_remove: Array[int] = []
		var this_scene: PackedStringArray = scenes[scene_name]
		var j: int = 0; var max = this_scene.size()-1
		while j <= max:
			if this_scene[j] == "":
				this_scene.remove_at(j)
				max -= 1
				continue
			j+=1
		
		scenes[scene_name].remove_at(0)
	
	#print(scenes)

func play_scene(name: String):
	assert (scenes.keys().has(name), "Scene "+name+" does not exist in "+str(scenes.keys()))
	play_from.emit(scenes[name])
