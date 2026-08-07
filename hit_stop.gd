extends Node

var consecutive_hits: int = 0
var reset_timer: SceneTreeTimer

func freeze(base_duration: float = 0.08) -> void:
	consecutive_hits += 1
	
	# Reduce duration with each hit in a row, with a floor so it never hits zero
	var scaled_duration = base_duration / (1.0 + (consecutive_hits - 1) * 0.3)
	scaled_duration = max(scaled_duration, 0.02)
	
	Engine.time_scale = 0.05
	var timer = get_tree().create_timer(scaled_duration, true, false, true)
	await timer.timeout
	Engine.time_scale = 1.0
	
	# Reset the combo counter if no hit lands again soon
	reset_timer = get_tree().create_timer(0.8, true, false, true)
	reset_timer.timeout.connect(_reset_combo)

func _reset_combo() -> void:
	consecutive_hits = 0
