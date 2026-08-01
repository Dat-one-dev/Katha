extends PanelContainer

# --- Configurable Parameters ---
@export_range(1.0, 100.0) var characters_per_second: float = 30.0

# --- Node References ---
## Drag and drop your RichTextLabel node into this slot in the Inspector!
@export var label: RichTextLabel

@onready var dialogue_box: Control = self

# --- State Variables ---
var dialogue_lines: Array[String] = []
var current_line_index: int = 0
var is_typing: bool = false
var is_active: bool = false

## The dialogue box that actually lives in the scene. The autoload singleton
## (registered in project.godot) uses this reference to drive that instance.
var ui: PanelContainer

var tween: Tween
var typing_tween: Tween

func _ready() -> void:
	# Fallback search if forget to assign in Inspector
	if not label:
		label = get_node_or_null("Label") as RichTextLabel
	if not label:
		label = find_child("*Label*", true, false) as RichTextLabel

	if not label:
		# The autoload singleton has no children; it exists only so
		# DialogueManager.start_dialogue() can be called globally. The real UI
		# registers itself below once the main scene loads.
		if get_tree().current_scene == null:
			return
		push_error("DialogueManager: Missing RichTextLabel! Please assign it in the Inspector.")
		return

	# This instance is the dialogue box inside the scene: expose it to the singleton.
	DialogueManager.ui = self

	# Hide the dialogue box on launch without triggering animations
	dialogue_box.modulate.a = 0.0
	dialogue_box.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		
		if is_typing:
			# Immediately reveal the entire current sentence
			finish_typing_instantly()
		else:
			# Advance to next sentence or close
			current_line_index += 1
			if current_line_index < dialogue_lines.size():
				show_current_line()
			else:
				end_dialogue()

## Call this to initiate a conversation sequence
func start_dialogue(lines: Array[String]) -> void:
	# When called on the autoload singleton, forward to the UI in the scene.
	if ui and ui != self:
		ui.start_dialogue(lines)
		return

	if lines.is_empty() or is_active or not label:
		return

	dialogue_lines = lines
	current_line_index = 0
	is_active = true

	# Disable player movement
	toggle_player_movement(false)

	# Smoothly fade in the UI box
	fade_ui(true)
	show_current_line()

## Displays text with a letter-by-letter typing effect
func show_current_line() -> void:
	if not label:
		return

	if typing_tween and typing_tween.is_running():
		typing_tween.kill()

	var text: String = dialogue_lines[current_line_index]
	label.text = text
	label.visible_characters = 0
	
	var total_chars: int = label.get_total_character_count()
	var duration: float = total_chars / characters_per_second

	is_typing = true

	typing_tween = create_tween()
	typing_tween.tween_property(label, "visible_characters", total_chars, duration)\
		.from(0)\
		.set_trans(Tween.TRANS_LINEAR)
	
	typing_tween.finished.connect(func(): is_typing = false)

## Instantly completes the currently typing text block
func finish_typing_instantly() -> void:
	if not label:
		return

	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
	
	label.visible_characters = label.get_total_character_count()
	is_typing = false

## Cleans up state and fades out dialogue box
func end_dialogue() -> void:
	is_active = false
	fade_ui(false)
	
	# Enable player movement again
	toggle_player_movement(true)

## Fades the dialogue panel in or out using Godot 4 Tweens
func fade_ui(fade_in: bool) -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()

	if fade_in:
		dialogue_box.show()
		tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN)
		tween.finished.connect(dialogue_box.hide)

## Utility to freeze or enable player input safely via group call
func toggle_player_movement(enable: bool) -> void:
	var players = get_tree().get_nodes_in_group("Player")
	for player in players:
		if "can_move" in player:
			player.can_move = enable
