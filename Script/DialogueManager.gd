extends PanelContainer

# --- Configurable Parameters ---
@export_range(1.0, 100.0) var characters_per_second: float = 35.0

# --- Node References ---
@export var label: RichTextLabel

@onready var dialogue_box: Control = self

# --- State Variables ---
var current_npc_name: String = ""
var current_personality: String = ""
var current_lore: String = ""
var current_memory: Array[Dictionary] = []

var is_typing: bool = false
var is_active: bool = false
var is_awaiting_ai: bool = false

var ui: PanelContainer
var tween: Tween
var typing_tween: Tween

func _ready() -> void:
	if not label:
		label = find_child("*Label*", true, false) as RichTextLabel

	DialogueManager.ui = self
	dialogue_box.modulate.a = 0.0
	dialogue_box.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	# 1. PRESS 'X' OR 'ESC' TO END DIALOGUE
	if event is InputEventKey and event.pressed and event.keycode == KEY_X or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_dialogue()
		return

	# 2. PRESS INTERACT (E / SPACE) TO SKIP OR CONTINUE
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		
		if is_typing:
			# If still typing, skip animation to show full text instantly
			finish_typing_instantly()
		elif not is_awaiting_ai:
			# If text is done typing, ask AI to continue the conversation
			_continue_ai_conversation()

## Opens dialogue window and manages conversation sequence
func start_ai_conversation(npc_name: String, personality: String, lore: String, memory_ref: Array[Dictionary]) -> void:
	if ui and ui != self:
		await ui.start_ai_conversation(npc_name, personality, lore, memory_ref)
		return

	if is_active:
		return

	current_npc_name = npc_name
	current_personality = personality
	current_lore = lore
	current_memory = memory_ref

	is_active = true
	toggle_player_movement(false)
	fade_ui(true)

	# Start initial conversation
	if current_memory.is_empty():
		_send_prompt_to_ai("The player approaches you and greets you.")
	else:
		_send_prompt_to_ai("The player approaches you again to speak.")

## Called when player presses Space/E after a line finishes
func _continue_ai_conversation() -> void:
	_send_prompt_to_ai("The player nods and listens to hear more.")

func _send_prompt_to_ai(prompt: String) -> void:
	is_awaiting_ai = true
	show_text("Thinking...")

	var is_system_trigger: bool = prompt.begins_with("The player approaches") or prompt.begins_with("The player nods")
	if not is_system_trigger:
		current_memory.append({"role": "user", "content": prompt})

	var ai_reply: String = await AIManager.ask(current_npc_name, current_personality, current_lore, current_memory)

	if not is_active:
		return

	current_memory.append({"role": "assistant", "content": ai_reply})

	if current_memory.size() > 12:
		current_memory = current_memory.slice(current_memory.size() - 12)

	is_awaiting_ai = false
	show_text(ai_reply)

func show_text(text: String) -> void:
	if not label:
		return

	if typing_tween and typing_tween.is_running():
		typing_tween.kill()

	label.text = text
	label.visible_characters = 0
	
	var total_chars: int = label.get_total_character_count()
	var duration: float = total_chars / characters_per_second

	is_typing = true

	typing_tween = create_tween()
	typing_tween.tween_property(label, "visible_characters", total_chars, duration)\
		.from(0)\
		.set_trans(Tween.TRANS_LINEAR)
	
	typing_tween.finished.connect(func():
		is_typing = false
	)

func finish_typing_instantly() -> void:
	if not label:
		return

	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
	
	label.visible_characters = label.get_total_character_count()
	is_typing = false

func end_dialogue() -> void:
	if not is_active:
		return

	is_active = false
	is_awaiting_ai = false

	fade_ui(false)
	toggle_player_movement(true)

func fade_ui(fade_in: bool) -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()

	if fade_in:
		dialogue_box.show()
		tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN)
		tween.finished.connect(dialogue_box.hide)

func toggle_player_movement(enable: bool) -> void:
	print("[DEBUG] Toggle player movement:", enable)
	var players = get_tree().get_nodes_in_group("Player")
	print("[DEBUG] Players found in group:", players.size())
	for player in players:
		if "can_move" in player:
			player.can_move = enable
			print("[DEBUG] Set ", player.name, ".can_move = ", enable)
