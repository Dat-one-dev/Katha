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

@export_multiline var story_goal: String = """
Slowly reveal that the sacrifice is dishonest.

Initially defend your actions.

If Nachiketa questions the worth of the cows, become irritated.

If he repeatedly asks,ss
'To whom will you give me?'

lose your temper and finally shout exactly:

'To Death I give you!'

After saying this, the conversation is concluded.
"""

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

	await DialogueManager.start_ai_conversation(
		npc_name,
		personality,
		lore,
		story_goal,
		memory
	)

	is_talking = false
