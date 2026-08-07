extends CharacterBody2D

@export var max_health: int = 30
@export var move_speed: float = 100.0
@export var stop_distance: float = 40.0



@export var contact_damage: int = 10
@export var attack_cooldown: float = 1.0
var can_attack: bool = true

@onready var anim_player: AnimationPlayer = $AnimationPlayer

@onready var sprite: Sprite2D = $Sprite2D

var current_health: int
var player_ref: Node2D

var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_decay: float = 800.0

@export var surround_radius: float = 60.0
var surround_angle: float = 0.0


func _ready() -> void:
	current_health = max_health
	player_ref = get_tree().get_first_node_in_group("player")
	surround_angle = randf_range(0, TAU)

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return
	
	var target_position = player_ref.global_position + Vector2(cos(surround_angle), sin(surround_angle)) * surround_radius
	var distance = global_position.distance_to(target_position)
	var move_velocity = Vector2.ZERO
	var player_distance = global_position.distance_to(player_ref.global_position)

	if distance > stop_distance:
		var direction = global_position.direction_to(target_position)
		move_velocity = direction * move_speed
	
	var seperation = _get_separation_force()
	
	velocity = move_velocity + knockback_velocity + seperation
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	
	if velocity.x - knockback_velocity.x < 0:
		sprite.flip_h = true 
	else:
		sprite.flip_h = false
	move_and_slide()
	
	
	if can_attack and player_distance <= stop_distance:
		_attack_player()
		
func _get_separation_force() -> Vector2:
	var push = Vector2.ZERO
	var separation_distance = 40.0
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for other in enemies: 
		if other == self:
			continue
		var dist = global_position.distance_to(other.global_position)
		if dist < separation_distance and dist > 0:
			var away = global_position.direction_to(other.global_position) * -1
			push += away * (separation_distance - dist) * 3
	return push

func _attack_player() -> void:
	if player_ref.has_method("take_damage"):
		var push_dir = global_position.direction_to(player_ref.global_position)
		player_ref.take_damage(contact_damage, push_dir , 300.0)
	anim_player.play("attack")
	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true	
	
func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction * force

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	current_health -= amount
	print("Enemy took ", amount, " damage. Health: ", current_health)
	apply_knockback(knockback_dir, knockback_force)
	if current_health <= 0:
		die()

func die() -> void:
	print("Enemy defeated")
	queue_free()
	
 
