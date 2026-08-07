extends Node2D

@export var melee_enemy_scene: PackedScene
@export var ranged_enemy_scene: PackedScene
@export var spawn_positions: Array[Vector2] = []
@export var enemies_per_wave: int = 4
@export var wave_delay: float = 2.0
@export var max_waves: int = 0  # 0 = infinite

var current_wave: int = 0
var enemies_alive: int = 0

func _ready() -> void:
	_start_wave()

func _start_wave() -> void:
	current_wave += 1
	print("Wave ", current_wave, " starting")
	
	if spawn_positions.is_empty():
		print("No spawn positions set!")
		return
	
	for i in enemies_per_wave:
		_spawn_random_enemy()

func _spawn_random_enemy() -> void:
	var scene_pool = [melee_enemy_scene, ranged_enemy_scene]
	var chosen_scene = scene_pool[randi() % scene_pool.size()]
	if chosen_scene == null:
		return
	
	var enemy = chosen_scene.instantiate()
	var spawn_pos = spawn_positions[randi() % spawn_positions.size()]
	
	call_deferred("_add_enemy_to_scene", enemy, spawn_pos)
	
func _add_enemy_to_scene(enemy: Node, spawn_pos: Vector2) -> void:
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos
	enemies_alive += 1
	enemy.tree_exited.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		if max_waves == 0 or current_wave < max_waves:
			await get_tree().create_timer(wave_delay).timeout
			_start_wave()
		else:
			print("All waves cleared!")
