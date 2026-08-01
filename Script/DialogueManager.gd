extends PanelContainer

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
var current_npc_name: String = ""
var current_personality: String = ""
var current_lore: String = ""
var current_story_goal: String = ""
var current_memory: Array[Dictionary] = []
var active_choices: Array = []

var is_typing: bool = false
var is_active: bool = false
var is_awaiting_ai: bool = false

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

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	# ESC / X to exit instantly
	if event is InputEventKey and event.pressed and event.keycode == KEY_X or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_dialogue()
		return

	# Interact to skip typing
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if is_typing:
			get_viewport().set_input_as_handled()
			finish_typing_instantly()

## Opens dialogue window
func start_ai_conversation(npc_name: String, personality: String, lore: String, story_goal: String, memory_ref: Array[Dictionary]) -> void:
	if ui and ui != self:
		await ui.start_ai_conversation(npc_name, personality, lore, story_goal, memory_ref)
		return

	if is_active:
		return

	current_npc_name = npc_name
	current_personality = personality
	current_lore = lore
	current_story_goal = story_goal
	current_memory = memory_ref

	is_active = true
	toggle_player_movement(false)
	fade_ui(true)

	if current_memory.is_empty():
		_send_prompt_to_ai("The young boy Nachiketa approaches you and greets you.")
	else:
		_send_prompt_to_ai("Nachiketa approaches you again to speak.")

func _send_prompt_to_ai(prompt: String) -> void:
	is_awaiting_ai = true
	clear_choices()
	show_text("* (Thinking...)")

	var is_system_trigger: bool = prompt.begins_with("The young boy Nachiketa")
	if not is_system_trigger:
		current_memory.append({"role": "user", "content": prompt})

	var ai_response: Dictionary = await AIManager.ask(
		current_npc_name, 
		current_personality, 
		current_lore, 
		current_story_goal, 
		current_memory
	)

	if not is_active:
		return

	var ai_reply: String = ai_response.get("dialogue", "...")
	active_choices = ai_response.get("choices", [])
	
	if not active_choices.has("Goodbye."):
		active_choices.append("Goodbye.")

	current_memory.append({"role": "assistant", "content": ai_reply})

	if current_memory.size() > 12:
		current_memory = current_memory.slice(current_memory.size() - 12)

	is_awaiting_ai = false
	
	if not ai_reply.begins_with("*"):
		ai_reply = "* " + ai_reply
		
	show_text(ai_reply)

func show_text(text: String) -> void:
	if not label:
		return

	clear_choices()
	
	# Show dialogue label when NPC speaks
	label.show()

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
		_display_choices()
	)

func finish_typing_instantly() -> void:
	if not label:
		return

	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
	
	label.visible_characters = label.get_total_character_count()
	is_typing = false
	_display_choices()

## Generates Undertale choices with proper padding, font, and centering
func _display_choices() -> void:
	if is_awaiting_ai or not is_active or not choices_container:
		return

	# 1. Hide dialogue label so choices take over
	if label:
		label.hide()

	clear_choices()

	# 2. Configure container layout & inner margins
	choices_container.show()
	choices_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choices_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_container.alignment = BoxContainer.ALIGNMENT_CENTER

	for i in range(active_choices.size()):
		var option_text = String(active_choices[i])
		var btn = Button.new()
		
		btn.text = "* " + option_text
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# --- Custom Font Override ---
		if custom_font:
			btn.add_theme_font_override("font", custom_font)
			btn.add_theme_font_size_override("font_size", font_size)
		elif label: # Fallback to label font if custom_font slot is empty
			var label_font = label.get_theme_font("font")
			if label_font:
				btn.add_theme_font_override("font", label_font)
			var label_font_size = label.get_theme_font_size("font_size")
			if label_font_size > 0:
				btn.add_theme_font_size_override("font_size", label_font_size)

		# --- Transparent StyleBox with Left Padding ---
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
		
		# Colors: White normal, Undertale Yellow on hover/focus
		btn.add_theme_color_override("font_color", Color(1, 1, 1)) 
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 0)) 
		btn.add_theme_color_override("font_focus_color", Color(1, 1, 0)) 
		
		btn.pressed.connect(_on_choice_selected.bind(option_text))
		choices_container.add_child(btn)
		
		if i == 0:
			btn.grab_focus()

func clear_choices() -> void:
	if not choices_container:
		return
	for child in choices_container.get_children():
		child.queue_free()

func _on_choice_selected(choice_text: String) -> void:
	if choice_text == "Goodbye.":
		end_dialogue()
		return

	_send_prompt_to_ai(choice_text)

func end_dialogue() -> void:
	if not is_active:
		return

	is_active = false
	is_awaiting_ai = false

	clear_choices()
	if label:
		label.show()
	fade_ui(false)
	toggle_player_movement(true)

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

func toggle_player_movement(enable: bool) -> void:
	var players = get_tree().get_nodes_in_group("Player")
	for player in players:
		if "can_move" in player:
			player.can_move = enable
