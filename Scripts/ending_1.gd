extends Control

## Script attached to Ending1.tscn to manage ending sprite display.

# Dictionary mapping ending IDs to their respective Sprite2D node names
const SPRITE_MAPPING: Dictionary = {
	"SATYA": "1",
	"TYAKTA": "2",
	"LOBHA": "3"
}

@onready var sprite_1: Sprite2D = $"1"
@onready var sprite_2: Sprite2D = $"2"
@onready var sprite_3: Sprite2D = $"3"


func _ready() -> void:
	# Hide all ending sprites by default
	_hide_all_sprites()

	# Read the ending ID set by SceneTransition
	var target_ending: String = SceneTransition.ending_to_show

	# Display the target sprite if valid
	if SPRITE_MAPPING.has(target_ending):
		var target_node_name: String = SPRITE_MAPPING[target_ending]
		var target_sprite: Node = find_child(target_node_name, true, false)
		
		if target_sprite is Sprite2D:
			target_sprite.show()
		else:
			push_warning("Ending1: Node named '%s' is missing or not a Sprite2D." % target_node_name)
	else:
		push_warning("Ending1: Unrecognized ending ID '%s'." % target_ending)


## Hides all three ending sprites.
func _hide_all_sprites() -> void:
	if sprite_1:
		sprite_1.hide()
	if sprite_2:
		sprite_2.hide()
	if sprite_3:
		sprite_3.hide()
