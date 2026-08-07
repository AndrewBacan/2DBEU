extends Label

func _ready() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 20, 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(queue_free)

func set_damage(amount: int) -> void:
	text = str(amount)
