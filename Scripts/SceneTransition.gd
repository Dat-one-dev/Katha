extends Node

var ending_to_show: String = ""

const ENDING_SCENE_PATH: String = "res://Scenes/Ending1.tscn"

func change_to_ending(id: String) -> void:
	ending_to_show = id
	var change_err: Error = get_tree().change_scene_to_file(ENDING_SCENE_PATH)
	if change_err != OK:
		push_error("SceneTransition: Failed to change scene to " + ENDING_SCENE_PATH)
