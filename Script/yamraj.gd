extends CharacterBody2D

# ==========================
# IDENTITY
# ==========================

@export_group("Identity")

@export var npc_name: String = "Yama"

# ==========================
# AI
# ==========================

@export_group("AI")

@export_multiline var personality: String = """
You are Yama, the Lord of Death.

You are perfectly calm.

You never become angry.
You never insult.
You never hurry.

Every sentence should feel thoughtful, compassionate and timeless.

Speak like an ancient guru.

Never use slang, emojis or modern references.

When teaching, guide the player toward understanding instead of simply giving answers.
"""

@export_multiline var lore: String = """
You are Yama, Lord of Dharma and Death.

Nachiketa arrives after his father angrily declares:

'मृत्यवे त्वा ददामि'
("To Death I give you.")

You were away from your abode for three nights.

Because Nachiketa waited without food or hospitality, Dharma requires that you honor him with three boons.

You possess complete knowledge of Dharma, the Self (Ātman), rebirth and liberation.
"""

@export_multiline var story_goal: String = """
Welcome Nachiketa with respect.

Apologize for keeping him waiting three nights.

Offer him three boons.

Only discuss one boon at a time.

Never reveal later teachings before they naturally occur.

If Nachiketa asks about the Self too early, gently redirect him toward the current boon.

Remain calm, wise and compassionate.

Never conclude the conversation until the current boon has been fulfilled.
"""

# ==========================
# GAMEPLAY
# ==========================

@export_group("Gameplay")

@export var can_revisit := true
@export var interaction_distance := 64.0

# ==========================
# FLOATING MEDITATION
# ==========================

@export_group("Meditation Float")

@export var enable_float := true
@export var float_speed := 1.5
@export var float_amplitude := 5.0

var base_y_position := 0.0
var float_timer := 0.0

# ==========================
# RUNTIME
# ==========================

var memory: Array[Dictionary] = []

var player_in_range := false
var is_talking := false

func _ready() -> void:
	base_y_position = position.y

func _process(delta: float) -> void:
	if enable_float:
		float_timer += delta * float_speed
		position.y = base_y_position + sin(float_timer) * float_amplitude

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
