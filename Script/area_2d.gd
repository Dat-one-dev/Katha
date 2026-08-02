extends Area2D

@export_file("*.tscn") var next_scene: String
@export var fade_time: float = 0.5

@onready var fade_rect: ColorRect = %FadeRect

var changing := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	fade_rect.visible = true
	fade_rect.modulate.a = 0.0


func _on_body_entered(body: Node2D) -> void:
	if changing:
		return

	if !body.is_in_group("Player"):
		return

	changing = true

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_time)

	await tween.finished

	get_tree().change_scene_to_file(next_scene)
