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

@export_range(0, 5) var current_stage: int = 0

var stages: Array[Dictionary] = [
	# Stage 0: Arrival
	{
		"stage_start_text": "Welcome, child, to the abode of Death. You have waited three nights without food or hospitality. This is a great error on my part. To make amends, ask of me three boons—one for each night.",
		"prompt": "Yama has returned to his abode after 3 nights and sees Nachiketa. He apologizes for keeping him waiting and offers three boons. He must not teach Nachiketa about Atman/liberation yet. Keep response calm, Guru-like, and welcoming.",
		"choices": [
			{
				"text": "Who are you?",
				"description": "Nachiketa respectfully asks Yama who he is.",
				"next_stage": -1
			},
			{
				"text": "Why do you offer me three boons?",
				"description": "Nachiketa asks why Yama is offering three boons.",
				"next_stage": -1
			},
			{
				"text": "For my first boon, I ask that my father's anger be appeased.",
				"description": "Nachiketa accepts the offer and asks to appease his father's anger (transitions to First Boon).",
				"next_stage": 1
			}
		]
	},
	# Stage 1: First Boon
	{
		"stage_start_text": "A worthy first request. Reconciliation is the foundation of peace. For your first boon, your father Vajashravasa shall be pacified, free from anger, and shall recognize you when you return.",
		"prompt": "Yama has granted the first boon (father's reconciliation). Explain that his father's heart will soften and he will sleep peacefully. Encourage him to move to the second boon when he is ready.",
		"choices": [
			{
				"text": "Will my father truly forgive me?",
				"description": "Nachiketa asks if his father will truly forgive him and accept him back.",
				"next_stage": -1
			},
			{
				"text": "Thank you, Lord Yama. Now, for my second boon...",
				"description": "Nachiketa thanks Yama and states he is ready to ask for the second boon (transitions to Second Boon).",
				"next_stage": 2
			}
		]
	},
	# Stage 2: Second Boon
	{
		"stage_start_text": "Now, Nachiketa, what is the second boon you desire?",
		"prompt": "Nachiketa wants to learn the fire sacrifice that leads to the heavenly realm. Teach him about the Nachiketa Fire. Explain that heaven is free from hunger, fear, and old age, but is still a temporary realm compared to ultimate liberation. Encourage him to ask for the third boon when he is ready.",
		"choices": [
			{
				"text": "Teach me the fire sacrifice that leads to heaven.",
				"description": "Nachiketa asks to be taught the fire sacrifice that leads to heaven.",
				"next_stage": -1
			},
			{
				"text": "Why is this sacrifice named after me?",
				"description": "Nachiketa asks why Yama named this fire sacrifice after him.",
				"next_stage": -1
			},
			{
				"text": "I understand. Now I ask for the third boon.",
				"description": "Nachiketa says he understands and is ready to ask for the third boon (transitions to Third Boon).",
				"next_stage": 3
			}
		]
	},
	# Stage 3: Third Boon (The Ask)
	{
		"stage_start_text": "The first two boons are granted. Now, ask for your third boon, Nachiketa.",
		"prompt": "Nachiketa is asking the ultimate question: what happens after death? Refuse to answer initially. Tell him that even the gods had doubts about this, and it is too subtle to understand. Urge him to choose another boon instead.",
		"choices": [
			{
				"text": "What happens after death? Does the soul exist?",
				"description": "Nachiketa asks the ultimate question: what happens to a person after death, and if the soul exists.",
				"next_stage": 4
			},
			{
				"text": "Why is this secret so difficult to know?",
				"description": "Nachiketa asks why this secret is so difficult that even the gods had doubts (transitions to Temptation).",
				"next_stage": 4
			}
		]
	},
	# Stage 4: Temptation
	{
		"stage_start_text": "Ask for sons and grandsons who live a hundred years, gold, horses, elephants, or a vast kingdom. Choose long life and worldly pleasures. Do not press me on the secret of death.",
		"prompt": "Yama is testing Nachiketa. He offers immense worldly wealth, kingdoms, and pleasures. Respond by describing the wonders and riches you can give him, trying to tempt him away from his inquiry into death.",
		"choices": [
			{
				"text": "All worldly pleasures are transient. I only want the knowledge of the Self.",
				"description": "Nachiketa rejects all worldly pleasures as transient and demands only the knowledge of the Self (transitions to Teaching of Atman).",
				"next_stage": 5
			},
			{
				"text": "I accept your offer of wealth, power, and long life.",
				"description": "Nachiketa accepts Yama's offer of wealth, power, and long life (concludes conversation, LOBHA ending).",
				"next_stage": -1,
				"concludes": true,
				"ending": "LOBHA"
			},
			{
				"text": "Why do you tempt me with things that must decay?",
				"description": "Nachiketa questions why Yama tries to tempt him with things that must decay.",
				"next_stage": -1
			}
		]
	},
	# Stage 5: Teaching of Atman
	{
		"stage_start_text": "You are indeed a steadfast seeker, Nachiketa. You have rejected the pleasant (Preya) and chosen the good (Shreya). I shall teach you of the eternal Self, the Atman, which is never born and never dies.",
		"prompt": "Yama is teaching Nachiketa about the Atman (the Self). The Atman is eternal, deathless, and can only be known through inner realization and meditation, not through logic or wealth. Explain these concepts with deep wisdom.",
		"choices": [
			{
				"text": "How is the Atman different from the body?",
				"description": "Nachiketa asks how the Atman differs from the physical body.",
				"next_stage": -1
			},
			{
				"text": "I choose the path of ultimate truth and renunciation.",
				"description": "Nachiketa chooses the path of ultimate truth and renunciation (concludes conversation, SATYA ending).",
				"next_stage": -1,
				"concludes": true,
				"ending": "SATYA"
			},
			{
				"text": "I wish to return to the world and perform my duties with this wisdom.",
				"description": "Nachiketa chooses to return to the world to perform his duties with this wisdom (concludes conversation, TYAKTA ending).",
				"next_stage": -1,
				"concludes": true,
				"ending": "TYAKTA"
			}
		]
	}
]

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

	await DialogueManager.start_ai_conversation(self)

	is_talking = false
