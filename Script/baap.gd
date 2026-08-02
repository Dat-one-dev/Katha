extends CharacterBody2D

# ==========================
# NPC INFORMATION
# ==========================

@export_group("Identity")

@export var npc_name: String = "Vajashravasa"
@export var age: int = 60
@export var role: String = "Householder and performer of the Vishwajit sacrifice"

# ==========================
# AI PERSONALITY
# ==========================

@export_group("AI")

@export_multiline var personality: String = """
Proud.
Easily irritated.
Believes he is righteous.
Cares deeply about reputation and ritual.
Avoids admitting mistakes.
"""

@export_multiline var lore: String = """
Vajashravasa is performing the Vishwajit Yajna to gain religious merit.

Instead of donating his best possessions, he is giving away old, weak,
blind and barren cows that have no value.

His son Nachiketa notices this hypocrisy.

He genuinely believes he is performing Dharma, yet his attachment to
wealth blinds him.
"""

@export_range(0, 2) var current_stage: int = 0

var stages: Array[Dictionary] = [
	# Stage 0: The Sacrifice
	{
		"stage_start_text": "Welcome, my son Nachiketa. See the grand sacrifice I perform! I am giving away my possessions to earn great merit in the eyes of the gods.",
		"prompt": "Vajashravasa is performing the Vishwajit sacrifice. He is proud but defensive. He is donating old, useless cows. If Nachiketa asks about the cows, justify it as part of the ritual and get slightly annoyed. Speak directly, proudly, and defensively.",
		"choices": [
			{
				"text": "Father, why are you donating these old, weak cows?",
				"description": "Nachiketa asks why his father is donating old, weak cows.",
				"next_stage": -1
			},
			{
				"text": "These cows have eaten their last grass. What merit can you gain from this?",
				"description": "Nachiketa points out the cows have eaten their last grass and asks what merit his father can gain.",
				"next_stage": 1
			}
		]
	},
	# Stage 1: Nachiketa's Question
	{
		"stage_start_text": "How dare you question my sacrifice! You are just a boy. Go play and do not interfere in holy matters.",
		"prompt": "Vajashravasa is angry that his son is questioning his ritual's integrity. If Nachiketa asks who he will be given to, ignore the question, dismiss him, or tell him to shut up. Speak with irritation and pride.",
		"choices": [
			{
				"text": "A son is also a possession. To whom will you give me?",
				"description": "Nachiketa asks his father to whom he will give him, since a son is also a possession.",
				"next_stage": -1
			},
			{
				"text": "Father, answer me. To whom will you give me?",
				"description": "Nachiketa insists and asks again to whom he will be given.",
				"next_stage": 2
			}
		]
	},
	# Stage 2: The Curse
	{
		"stage_start_text": "Silence, boy! Stop pestering me!",
		"prompt": "Vajashravasa has reached his breaking point. If Nachiketa asks again who he will be given to, explode in anger and shout exactly: 'To Death I give you!'",
		"choices": [
			{
				"text": "Father, for the third time: to whom will you give me?",
				"description": "Nachiketa demands for the third time to know to whom he will be given.",
				"next_stage": -1,
				"concludes": true,
				"ending": ""
			}
		]
	}
]

# ==========================
# GAMEPLAY & VISUALS
# ==========================

@export_group("Gameplay")

@export var can_revisit: bool = false
@export var interaction_distance: float = 64.0

@export_group("Float Settings")
@export var enable_float: bool = true
@export var float_speed: float = 3.0    # How fast he bobs up and down
@export var float_amplitude: float = 6.0 # How high/low he floats in pixels

# ==========================
# RUNTIME
# ==========================

var memory: Array[Dictionary] = []

var player_in_range := false
var is_talking := false

var base_y_position: float = 0.0
var float_timer: float = 0.0

func _ready() -> void:
	# Store the initial Y position so he floats relative to where you placed him in the editor
	base_y_position = position.y

func _process(delta: float) -> void:
	if enable_float:
		float_timer += delta * float_speed
		# Uses a sine wave to smoothly move position up and down
		position.y = base_y_position + (sin(float_timer) * float_amplitude)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if !player_in_range:
		return

	if is_talking:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		start_talk()

func start_talk() -> void:
	is_talking = true

	await DialogueManager.start_ai_conversation(self)

	is_talking = false
