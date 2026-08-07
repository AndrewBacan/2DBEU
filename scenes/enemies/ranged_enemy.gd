extends CharacterBody2D

@export var max_health: int = 20
@export var preferred_distance: float = 350.0
@export var move_speed: float = 80.0
@export var fire_cooldown: float = 1.5
@export var projectile_scene: PackedScene

@export var floor_top: float = 100.0
@export var floor_bottom: float = 700.0

var can_fire: bool = true
var current_health: int
var player_ref: Node2D
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_decay: float = 800.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	current_health = max_health
	player_ref = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return

	var distance = global_position.distance_to(player_ref.global_position)
	var move_velocity = Vector2.ZERO

	if distance < preferred_distance - 20:
		var away = player_ref.global_position.direction_to(global_position)
		move_velocity = away * move_speed
	elif distance > preferred_distance + 20:
		var toward = global_position.direction_to(player_ref.global_position)
		move_velocity = toward * move_speed

	velocity = move_velocity + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	
	if velocity.x < 0:
		sprite.flip_h = true 
	else:
		sprite.flip_h = false
	
	move_and_slide()
	


	if can_fire:
		_fire_projectile()

func _fire_projectile() -> void:
	if projectile_scene == null:
		return
	can_fire = false
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	var fire_direction = global_position.direction_to(player_ref.global_position)
	proj.global_position = global_position + (fire_direction * 10)
	proj.launch(fire_direction)
	await get_tree().create_timer(fire_cooldown).timeout
	can_fire = true

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction * force

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	current_health -= amount
	print("Ranged enemy took damage. Health: ", current_health)
	apply_knockback(knockback_dir, knockback_force)
	if current_health <= 0:
		die()

func die() -> void:
	print("Ranged enemy defeated")
	queue_free()
