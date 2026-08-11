extends ProgressBar

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.current_health, player.max_health)


func _on_health_changed(new_health: int, max_health: int) -> void:
	max_value = max_health
	value = new_health
	
	var pct = float(new_health) / float(max_health)
	var fill_style = get_theme_stylebox("fill").duplicate()
	if pct > 0.5:
		fill_style.bg_color = Color(0.2, 0.8, 0.3)  # green
	elif pct > 0.25:
		fill_style.bg_color = Color(0.9, 0.7, 0.1)  # yellow
	else:
		fill_style.bg_color = Color(0.85, 0.2, 0.2)  # red
	add_theme_stylebox_override("fill", fill_style)
