extends CharacterBody2D

# Configurable dialogue array directly in the Inspector
@export var lines: Array[String] = [
	"Father...",
	"Why are these cows so weak?",
	"To whom will you give me?",
	"[color=red]To Death.[/color]" # BBCode enabled!
]

# Tracks whether this area has been triggered already
var has_triggered: bool = false

func _on_body_entered(body: Node2D) -> void:
	# Ignore if already triggered once or if body isn't the Player
	if has_triggered or not body.is_in_group("Player"):
		return

	has_triggered = true
	
	# Start dialogue via the DialogueManager singleton
	DialogueManager.start_dialogue(lines)
