extends Node

## Singleton manager responsible for handling scene transitions with fade animations.

# Stores the ID of the ending to display in Ending1.tscn
var ending_to_show: String = ""

# Path to the ending scene
const ENDING_SCENE_PATH: String = "res://Scene/Ending1.tscn"


## Fades out the screen using %FadeRect, switches to Ending1.tscn, and fades back in.
## [param id]: The identifier string for the ending ("SATYA", "TYAKTA", or "LOBHA").
func change_to_ending(id: String) -> void:
	ending_to_show = id

	# 1. Locate %FadeRect in the currently running scene tree
	var fade_rect: Control = get_tree().current_scene.find_child("FadeRect", true, false) as Control

	if fade_rect:
		# Ensure FadeRect is visible and starts at current alpha
		fade_rect.show()
		
		# Animate alpha from 0 to 1 over 0.5 seconds
		var fade_out_tween: Tween = create_tween()
		fade_out_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5)\
			.from(0.0)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
		
		await fade_out_tween.finished
	else:
		push_warning("SceneTransition: '%FadeRect' was not found in the current scene. Changing scene without fade out.")

	# 2. Change the scene to Ending1.tscn
	var change_err: Error = get_tree().change_scene_to_file(ENDING_SCENE_PATH)
	if change_err != OK:
		push_error("SceneTransition: Failed to change scene to " + ENDING_SCENE_PATH)
		return

	# Wait for the new scene tree to initialize
	await get_tree().process_frame

	# 3. Locate %FadeRect in the newly loaded scene to perform fade-in
	var new_fade_rect: Control = get_tree().current_scene.find_child("FadeRect", true, false) as Control

	if new_fade_rect:
		new_fade_rect.show()
		
		# Animate alpha from 1 to 0 over 0.5 seconds
		var fade_in_tween: Tween = create_tween()
		fade_in_tween.tween_property(new_fade_rect, "modulate:a", 0.0, 0.5)\
			.from(1.0)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
		
		await fade_in_tween.finished
