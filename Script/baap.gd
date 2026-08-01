extends CharacterBody2D

@export var npc_name: String = "Vajasravasa"
@export var personality: String = "Arrogant, stressed ritualist performing the Sarvamedha sacrifice. Easily annoyed."
@export_multiline var lore: String = "He is giving away old, useless cows to gain spiritual merit."
@export_multiline var story_goal: String = "Defend your sacrificial offerings. If Nachiketa asks who he will be given to, get angry and yell 'To Death I give you!'."

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
	if player_in_range and not is_talking and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		start_talk()

func start_talk() -> void:
	is_talking = true
	await DialogueManager.start_ai_conversation(npc_name, personality, lore, story_goal, memory)
	is_talking = false
