extends ProgressBar

@onready var player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	max_value = 1.0
	value = 1.0

func _process(delta: float) -> void:
	if player == null:
		return
	if player.can_special:
		value = 1.0
	else:
		# Approximate fill based on elapsed time — see note below
		value = min(value + delta / player.special_cooldown, 1.0)
