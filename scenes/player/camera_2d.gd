extends Camera2D

var shake_strength: float = 0.0
@export var shake_decay: float = 5.0

func _process(delta: float) -> void:
	if shake_strength > 0:
		offset = Vector2(
			randf_range(-1, 1) * shake_strength,
			randf_range(-1, 1) * shake_strength
		)
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
	else:
		offset = Vector2.ZERO

func shake(amount: float) -> void:
	shake_strength = amount
