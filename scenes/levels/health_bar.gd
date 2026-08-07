extends ProgressBar

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.current_health, player.max_health)

func _on_health_changed(new_health: int, max_health: int) -> void:
	max_value = max_health
	value = new_health
