extends CharacterBody2D

@export var npc_name: String = "Village Elder"
@export var personality: String = "Wise, calm, and slightly secretive elder."
@export_multiline var lore: String = "He has spent 80 years guarding the ancient banyan tree."

var memory: Array[Dictionary] = []
var player_in_range: bool = false
var is_talking: bool = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	# Only start conversation if player is nearby, presses interact, and isn't already talking
	if player_in_range and not is_talking and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		start_talk()

func start_talk() -> void:
	is_talking = true
	await DialogueManager.start_ai_conversation(npc_name, personality, lore, memory)
	is_talking = false
