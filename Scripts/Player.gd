extends CharacterBody2D

# --- Exported Parameters ---
@export var max_speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1200.0

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- State Variables ---
## Controlled by DialogueManager to freeze player input during cutscenes
var can_move: bool = true
var last_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	# Automatically add player to the "Player" group for trigger detection
	add_to_group("Player")

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		print("[DEBUG] Player can_move current state:", can_move)
	# If movement is disabled, smoothly decelerate to zero and play idle animation
	if not can_move:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		update_animation("idle", last_direction)
		move_and_slide()
		return

	# Handle normal player movement input
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_vector != Vector2.ZERO:
		last_direction = input_vector
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
		update_animation("run", input_vector)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		update_animation("idle", last_direction)
	
	move_and_slide()

## Handles animation selection and horizontal sprite flipping
func update_animation(state: String, dir: Vector2) -> void:
	var dir_suffix := "Down"
	
	# Determine primary axis
	if abs(dir.x) > abs(dir.y):
		dir_suffix = "Side"
		# Flip the sprite horizontally if facing left
		animated_sprite.flip_h = dir.x < 0
	else:
		dir_suffix = "Down" if dir.y > 0 else "Up"
		# Keep sprite un-flipped when moving vertically
		animated_sprite.flip_h = false
	
	# Constructs names: "idleDown", "idleSide", "idleUp", "runDown", "runSide", "runUp"
	var anim_name := state + dir_suffix
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
