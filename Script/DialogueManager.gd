extends PanelContainer

## Singleton/Global manager for handling UI dialogue, typing effects, and AI conversation flow.

# --- Configurable Parameters ---
@export_range(1.0, 100.0) var characters_per_second: float = 35.0

# --- Node References ---
@export var label: RichTextLabel
@export var choices_container: VBoxContainer 

@onready var dialogue_box: Control = self

# --- Custom Font Exports ---
@export var custom_font: Font
@export var font_size: int = 16

# --- State Variables ---
var current_npc: Node = null
var current_npc_name: String = ""
var current_personality: String = ""
var current_lore: String = ""
var current_stage_prompt: String = ""
var current_stage_choices: Array = []
var selected_choice_data: Dictionary = {}
var current_memory: Array[Dictionary] = []

var is_typing: bool = false
var is_active: bool = false
var is_awaiting_ai: bool = false
var is_concluded: bool = false
var is_waiting_for_read_confirm: bool = false # Pauses dialogue after typing ends
var current_ending: String = ""               # Stores "SATYA", "TYAKTA", or "LOBHA" when triggered

# Dynamic Font & AI Choice text caching
var determination_font: Font = null
var generated_choices_text: Array = []
var is_fetching_choices: bool = false

var ui: PanelContainer
var tween: Tween
var typing_tween: Tween


func _ready() -> void:
	if not label:
		label = find_child("*Label*", true, false) as RichTextLabel
		
	if not choices_container:
		choices_container = find_child("*Choice*", true, false) as VBoxContainer

	DialogueManager.ui = self
	dialogue_box.modulate.a = 0.0
	dialogue_box.hide()
	clear_choices()

	# Load the determination font
	determination_font = load("res://FOnt/determination.ttf")


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	# 1. ESC / X to exit instantly
	if event is InputEventKey and event.pressed and event.keycode == KEY_X or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_dialogue()
		return

	# 2. INTERACT KEY (Space / Enter / E)
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		# If text is actively typing -> Skip typing animation instantly
		if is_typing:
			get_viewport().set_input_as_handled()
			finish_typing_instantly()
			return

		# If text finished typing and player reads it -> Press Space to advance
		if is_waiting_for_read_confirm:
			get_viewport().set_input_as_handled()
			is_waiting_for_read_confirm = false
			_handle_read_confirmation()
			return


## Starts a new AI dialogue session with an NPC node
func start_ai_conversation(npc: Node) -> void:
	if ui and ui != self:
		await ui.start_ai_conversation(npc)
		return

	if is_active:
		return

	current_npc = npc
	current_npc_name = npc.npc_name
	current_personality = npc.personality
	current_lore = npc.lore
	current_memory = npc.memory
	is_concluded = false
	is_waiting_for_read_confirm = false
	current_ending = "" # Reset ending on new conversation start

	is_active = true
	toggle_player_movement(false)
	fade_ui(true)

	# Load current stage from NPC
	var stage_idx: int = current_npc.current_stage
	if stage_idx < 0 or stage_idx >= current_npc.stages.size():
		push_error("DialogueManager: NPC current_stage out of bounds.")
		end_dialogue()
		return
		
	var stage_data: Dictionary = current_npc.stages[stage_idx]
	current_stage_prompt = stage_data.get("prompt", "")
	current_stage_choices = (stage_data.get("choices", []) as Array).duplicate(true)
	selected_choice_data = {}

	# Background load the choices for this starting stage
	_fetch_choices_for_current_stage()

	# Instantly show the starting text of the current stage
	var start_text: String = stage_data.get("stage_start_text", "")
	if not start_text.is_empty():
		if not start_text.begins_with("*"):
			start_text = "* " + start_text
		show_text(start_text)
	else:
		_display_choices()


## Background fetches AI-generated choice texts for the current stage
func _fetch_choices_for_current_stage() -> void:
	is_fetching_choices = true
	generated_choices_text = []

	var choice_descriptions: Array = []
	for choice in current_stage_choices:
		choice_descriptions.append(choice.get("description", choice.get("text", "")))

	if choice_descriptions.is_empty():
		is_fetching_choices = false
		return

	# Query AI for generated choice options
	var ai_response: Dictionary = await AIManager.ask(
		current_npc_name,
		current_personality,
		current_lore,
		current_stage_prompt,
		choice_descriptions,
		current_memory
	)

	generated_choices_text = ai_response.get("choices", [])
	
	# Fallback to static text if AI choices are empty
	if generated_choices_text.is_empty():
		for choice in current_stage_choices:
			generated_choices_text.append(choice.get("text", ""))

	is_fetching_choices = false


## Sends prompt payload to AIManager and handles response
func _send_prompt_to_ai(prompt: String) -> void:
	is_awaiting_ai = true
	is_waiting_for_read_confirm = false
	clear_choices()
	show_text("* (Thinking...)")

	# Add choice prompt to memory
	current_memory.append({"role": "user", "content": prompt})

	# Get choice descriptions for the current stage to generate choices along with the dialogue response
	var choice_descriptions: Array = []
	for choice in current_stage_choices:
		choice_descriptions.append(choice.get("description", choice.get("text", "")))

	var ai_response: Dictionary = await AIManager.ask(
		current_npc_name, 
		current_personality, 
		current_lore, 
		current_stage_prompt, 
		choice_descriptions,
		current_memory
	)

	if not is_active:
		return

	var ai_reply: String = ai_response.get("dialogue", "...")
	generated_choices_text = ai_response.get("choices", [])
	
	# Fallback if AI didn't generate choices
	if generated_choices_text.is_empty():
		generated_choices_text = []
		for choice in current_stage_choices:
			generated_choices_text.append(choice.get("text", ""))

	current_memory.append({"role": "assistant", "content": ai_reply})

	# Keep memory bounded to prevent payload bloat
	if current_memory.size() > 12:
		current_memory = current_memory.slice(current_memory.size() - 12)

	is_awaiting_ai = false
	
	if not ai_reply.begins_with("*"):
		ai_reply = "* " + ai_reply
		
	show_text(ai_reply)


## Displays formatted text on screen with character typewriter effect
func show_text(text: String) -> void:
	if not label:
		return

	clear_choices()
	label.show()

	if typing_tween and typing_tween.is_running():
		typing_tween.kill()

	# Formats speaker name with BBCode color tags
	var full_text: String = text
	if not current_npc_name.is_empty() and text != "* (Thinking...)":
		full_text = "[color=yellow]" + current_npc_name + ":[/color]\n" + text

	label.text = full_text
	label.visible_characters = 0
	
	var total_chars: int = label.get_total_character_count()
	var duration: float = total_chars / characters_per_second

	is_typing = true
	is_waiting_for_read_confirm = false

	typing_tween = create_tween()
	typing_tween.tween_property(label, "visible_characters", total_chars, duration)\
		.from(0)\
		.set_trans(Tween.TRANS_LINEAR)
	
	typing_tween.finished.connect(func():
		is_typing = false
		_on_typing_completed()
	)


## Forces dialogue text to print instantly when interact key is pressed mid-type
func finish_typing_instantly() -> void:
	if not label:
		return

	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
	
	label.visible_characters = label.get_total_character_count()
	is_typing = false
	_on_typing_completed()


## Triggered when text finishes typing. Waits for user to press Space/Interact before showing options
func _on_typing_completed() -> void:
	# If the NPC was just "Thinking...", jump straight to receiving the AI response
	if is_awaiting_ai:
		return
		
	is_waiting_for_read_confirm = true


## Handles reading confirmation (Space / Accept) to advance dialogue or show choices
func _handle_read_confirmation() -> void:
	if not selected_choice_data.is_empty():
		var choice = selected_choice_data
		
		# 1. If this choice concludes the conversation
		if choice.get("concludes", false):
			current_ending = choice.get("ending", "")
			end_dialogue()
			return

		# 2. If this choice transitions the stage
		var next_stage: int = choice.get("next_stage", -1)
		if next_stage >= 0 and next_stage != current_npc.current_stage:
			current_npc.current_stage = next_stage
			current_npc.memory.clear()
			current_memory = current_npc.memory
			selected_choice_data = {}
			
			var stage_data: Dictionary = current_npc.stages[next_stage]
			current_stage_prompt = stage_data.get("prompt", "")
			current_stage_choices = (stage_data.get("choices", []) as Array).duplicate(true)
			
			# Asynchronously fetch choices for the new stage in background
			_fetch_choices_for_current_stage()
			
			var start_text: String = stage_data.get("stage_start_text", "")
			if not start_text.is_empty():
				if not start_text.begins_with("*"):
					start_text = "* " + start_text
				show_text(start_text)
			else:
				_display_choices()
			return

		# 3. Otherwise, stay in current stage, show choices again
		selected_choice_data = {}
		_display_choices()
	else:
		# Just finished showing stage start text, show choices
		_display_choices()


## Generates choice buttons after player confirms reading
func _display_choices() -> void:
	if is_awaiting_ai or not is_active or not choices_container:
		return

	# Wait if background fetching is still in progress
	if is_fetching_choices:
		show_text("* (Thinking...)")
		is_awaiting_ai = true
		while is_fetching_choices:
			await get_tree().process_frame
		is_awaiting_ai = false
		if label:
			label.hide()

	# Hide dialogue text now that player confirmed reading it
	if label:
		label.hide()

	clear_choices()

	choices_container.show()
	choices_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choices_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_container.alignment = BoxContainer.ALIGNMENT_CENTER

	var choices_to_show = current_stage_choices.duplicate(true)
	if choices_to_show.is_empty():
		choices_to_show = [{"text": "(Leave conversation)", "concludes": true}]

	# The AI improvises one extra, fully original follow-up question beyond the
	# scripted ones (see AIManager.ask). Show it as a bonus choice — it always
	# just stays in the current stage, so it can never break story progression.
	if generated_choices_text.size() > choices_to_show.size():
		var bonus_text: String = String(generated_choices_text[choices_to_show.size()])
		if not bonus_text.is_empty():
			choices_to_show.append({"text": bonus_text, "next_stage": -1, "ai_improvised": true})

	for i in range(choices_to_show.size()):
		var choice_data = choices_to_show[i]
		
		# Get dynamic AI-generated text if available, fallback to static text
		var option_text = ""
		if i < generated_choices_text.size():
			option_text = String(generated_choices_text[i])
		if option_text.is_empty():
			option_text = choice_data.get("text", "")

		var btn = Button.new()
		
		btn.text = ("~ " if choice_data.get("ai_improvised", false) else "* ") + option_text
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Apply determination font
		if determination_font:
			btn.add_theme_font_override("font", determination_font)
			btn.add_theme_font_size_override("font_size", font_size)
		elif custom_font:
			btn.add_theme_font_override("font", custom_font)
			btn.add_theme_font_size_override("font_size", font_size)
		elif label:
			var label_font = label.get_theme_font("font")
			if label_font:
				btn.add_theme_font_override("font", label_font)
			var label_font_size = label.get_theme_font_size("font_size")
			if label_font_size > 0:
				btn.add_theme_font_size_override("font_size", label_font_size)

		var flat_style = StyleBoxFlat.new()
		flat_style.bg_color = Color(0, 0, 0, 0)
		flat_style.content_margin_left = 24.0
		flat_style.content_margin_right = 24.0
		flat_style.content_margin_top = 4.0
		flat_style.content_margin_bottom = 4.0
		
		btn.add_theme_stylebox_override("normal", flat_style)
		btn.add_theme_stylebox_override("hover", flat_style)
		btn.add_theme_stylebox_override("pressed", flat_style)
		btn.add_theme_stylebox_override("focus", flat_style)
		
		var is_bonus: bool = choice_data.get("ai_improvised", false)
		btn.add_theme_color_override("font_color", Color(0.6, 1, 1) if is_bonus else Color(1, 1, 1))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 0)) 
		btn.add_theme_color_override("font_focus_color", Color(1, 1, 0)) 
		
		btn.pressed.connect(_on_choice_selected.bind(choice_data, i))
		choices_container.add_child(btn)
		
		if i == 0:
			btn.grab_focus()


## Clears existing choice buttons
func clear_choices() -> void:
	if not choices_container:
		return
	for child in choices_container.get_children():
		child.queue_free()


## Handles choice button selection
func _on_choice_selected(choice: Dictionary, index: int = -1) -> void:
	var choice_text = choice.get("text", "")
	if choice_text == "Goodbye." or choice_text == "(Leave conversation)" or is_concluded:
		end_dialogue()
		return

	selected_choice_data = choice

	# Once a "side question" (one that doesn't end/advance the stage) has been asked,
	# remove it from the pool so it can't be picked again and the same exchange
	# doesn't keep looping back into the menu.
	if not choice.get("concludes", false) and index >= 0 and index < current_stage_choices.size():
		if current_stage_choices[index] == choice:
			current_stage_choices.remove_at(index)
			if index < generated_choices_text.size():
				generated_choices_text.remove_at(index)

	_send_prompt_to_ai(choice_text)


## Closes dialogue window and triggers ending scene transition if an ending ID was received
func end_dialogue() -> void:
	if not is_active:
		return

	is_active = false
	is_awaiting_ai = false
	is_waiting_for_read_confirm = false

	clear_choices()
	if label:
		label.show()
	fade_ui(false)
	toggle_player_movement(true)

	# --- TRIGGER ENDING TRANSITION IF AN ENDING WAS REACHED ---
	if not current_ending.is_empty():
		SceneTransition.change_to_ending(current_ending)


## Smoothly fades the dialogue overlay in or out
func fade_ui(fade_in: bool) -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()

	if fade_in:
		dialogue_box.show()
		tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.1)
	else:
		tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.1)
		tween.finished.connect(dialogue_box.hide)


## Toggles player character movement script state
func toggle_player_movement(enable: bool) -> void:
	var players = get_tree().get_nodes_in_group("Player")
	for player in players:
		if "can_move" in player:
			player.can_move = enable
