extends CharacterBody2D
#region General Variables
# How fast the player moves, in pixels per second
@export var speed: float = 200.0

# The floor band: player's Y position can't go outside this range
@export var floor_top: float = 300.0
@export var floor_bottom: float = 500.0

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_timer: Timer = $AttackHitbox/AttackTimer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

#-----------------Block--------------
var is_blocking: bool = false
@export var block_damage_reduction: float = 0.8
@export var block_speed_multiplier: float = 0.3

#-----------------Evade-------------
var is_dashing: bool = false
var can_dash: bool = true
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.6
@export var dash_decay: float = 800.0

@export var max_health: int = 100
var current_health: int
var is_invulnerable: bool = false
@export var invulnerable_duration: float = 0.5

#-----------------Special: Shockwave Dash-------------
var can_special: bool = true
@export var special_cooldown: float = 5.0
@export var special_dash_speed: float = 900.0
@export var special_dash_duration: float = 0.25
@export var special_dash_decay: float = 1200.0
@export var special_damage: int = 20
@export var special_dash_hit_radius: float = 50.0
@export var shockwave_radius: float = 150.0
@export var shockwave_knockback: float = 400.0
var special_hit_targets: Array = []  # tracks who's already been hit this dash, prevents multi-hits
@export var special_dash_damage: int = 12
@export var special_shockwave_damage: int = 25

@onready var anim_player: AnimationPlayer = $AnimationPlayer

var is_attacking: bool = false

var facing_left: bool = false

var is_dead: bool = false

var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_decay: float = 800.0
@export var attack_knockback_force: float = 250.0

var dash_velocity: Vector2 = Vector2.ZERO

var combo_step: int = 0
var combo_window_open: bool = false
var queued_next_attack: bool = false

@export var damage_number_scene: PackedScene

signal health_changed(new_health: int, max_health: int)
#endregion

#region Ready and Physics Process
func _ready() -> void:
	# Hitbox should be OFF until we actually attack
	attack_hitbox.monitoring = false
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	current_health = max_health 
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	health_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	is_blocking = Input.is_action_pressed("block") and not is_attacking and not is_dashing
	# Get input direction from arrow keys / WASD
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
	
	# Normalize so diagonal movement isn't faster than straight movement
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
	
	var current_speed = speed * block_speed_multiplier if is_blocking else speed
	velocity = (input_direction * current_speed) + knockback_velocity + dash_velocity
		
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	dash_velocity = dash_velocity.move_toward(Vector2.ZERO, dash_decay * delta)
	
	if not is_attacking and not is_invulnerable:
			if is_blocking:
				sprite.play("defend")
			elif input_direction.length() > 0:
				sprite.play("walk")
				if velocity.x < 0: 
					sprite.flip_h = true
					attack_hitbox.position.x = abs(attack_hitbox.position.x) * (-1)
				else:
					sprite.flip_h = false
					attack_hitbox.position.x = abs(attack_hitbox.position.x)
			else:
				sprite.play("idle")
	
	move_and_slide()
	
	if Input.is_action_just_pressed("special") and can_special and not is_attacking and not is_blocking and not is_dashing:
		_start_special(input_direction)
	
	if Input.is_action_just_pressed("attack1"):
		if not is_attacking:
			combo_step = 0
			_start_attack()
		elif combo_window_open:
			queued_next_attack = true
	if Input.is_action_just_pressed("dash") and can_dash and not is_attacking and not is_blocking:
		_start_dash(input_direction)
#endregion

#region Mechanics and Animations

var attack_names = ["attack1", "attack2", "attack3"]

func _start_attack() -> void:
	is_attacking = true
	combo_window_open = false
	queued_next_attack = false
	print(attack_hitbox.position)
	
	var attack_animation = attack_names[combo_step]
	print("Playing: ", attack_animation)
	sprite.play(attack_animation)
	
	var duration = sprite.sprite_frames.get_frame_count(attack_animation) / sprite.sprite_frames.get_animation_speed(attack_animation)
	attack_timer.wait_time = duration
	attack_timer.start()
	
	var hit_delay = duration * 0.4
	await get_tree().create_timer(hit_delay).timeout
	if is_attacking:
		attack_hitbox.monitoring = true
	
	# Open the combo window for the last 50% of the swing
	var combo_window_delay = duration * 0.5
	await get_tree().create_timer(combo_window_delay - hit_delay).timeout
	if is_attacking:
		combo_window_open = true
		
func _start_dash(move_dir: Vector2) -> void:
	is_dashing = true
	can_dash = false
	is_invulnerable = true
	
	set_collision_layer_value(1, false)  # Player disappears from layer 1 entirely during dash
	
	var dash_direction = move_dir if move_dir.length() > 0 else (Vector2.LEFT if facing_left else Vector2.RIGHT)
	dash_velocity = dash_direction * dash_speed
	
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	is_invulnerable = false
	
	set_collision_layer_value(1, true)  # Player becomes solid again
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
	
func _on_attack_timer_timeout() -> void:
	is_attacking = false
	attack_hitbox.monitoring = false
	combo_window_open = false
	
	if queued_next_attack:
		combo_step += 1
		if combo_step >= attack_names.size():
			combo_step = 0
		_start_attack()
	else:
		combo_step = 0

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	print("Hit something: ", area.name)
	var hit_owner = area.get_parent()
	if hit_owner.has_method("take_damage"):
		var push_dir = global_position.direction_to(hit_owner.global_position)
		hit_owner.take_damage(10, push_dir, 250.0)
		HitStop.freeze(0.08)
		$Camera2D.shake(2.0)
		_spawn_damage_number(hit_owner.global_position, 10)

func _spawn_damage_number(pos: Vector2, amount: int) -> void:
	if damage_number_scene == null:
		return
	var dmg_label = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(dmg_label)
	dmg_label.global_position = pos
	dmg_label.set_damage(amount)

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction * force
		
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	if is_invulnerable or is_dead:
		return
	
	var final_damage = amount
	if is_blocking:
		final_damage = int(amount * (1.0 - block_damage_reduction))
	
	if is_attacking:
		is_attacking = false
		attack_hitbox.monitoring = false
		attack_timer.stop()
	
	current_health -= final_damage
	health_changed.emit(current_health, max_health)
	if not is_blocking:
		sprite.play("hurt")
	apply_knockback(knockback_dir, knockback_force * (0.2 if is_blocking else 1.0))
	is_invulnerable = true
	await get_tree().create_timer(invulnerable_duration).timeout
	is_invulnerable = false
	if current_health <= 0:
		die()
		
	# Interrupt attack if currently mid-swing
	if is_attacking:
		is_attacking = false
		attack_hitbox.monitoring = false
		attack_timer.stop()	
	
func _start_special(move_dir: Vector2) -> void:
	var using_special = true
	can_special = false
	is_invulnerable = true
	special_hit_targets.clear()
	
	set_collision_layer_value(1, false)
	
	var special_direction = move_dir if move_dir.length() > 0 else (Vector2.LEFT if facing_left else Vector2.RIGHT)
	dash_velocity = special_direction * special_dash_speed
	
	var elapsed = 0.0
	while elapsed < special_dash_duration:
		_check_special_dash_hits()
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	
	dash_velocity = Vector2.ZERO
	set_collision_layer_value(1, true)
	is_invulnerable = false

	
	_trigger_shockwave()
	
	await get_tree().create_timer(special_cooldown).timeout
	can_special = true

func _check_special_dash_hits() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy in special_hit_targets:
			continue
		if global_position.distance_to(enemy.global_position) <= special_dash_hit_radius:
			if enemy.has_method("take_damage"):
				var push_dir = global_position.direction_to(enemy.global_position)
				enemy.take_damage(special_damage, push_dir, 200.0)
				special_hit_targets.append(enemy)

func _trigger_shockwave() -> void:
	HitStop.freeze(0.12)
	$Camera2D.shake(14.0)
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= shockwave_radius:
			if enemy.has_method("take_damage"):
				var push_dir = global_position.direction_to(enemy.global_position)
				enemy.take_damage(special_damage, push_dir, shockwave_knockback)	

func die() -> void:
	is_dead = true
	print("Player defeated")
	velocity = Vector2.ZERO
	sprite.play("death")
	
func _on_sprite_animation_finished() -> void:
	if sprite.animation == "hurt" and not is_dead:
		sprite.play("idle")
	
	
func _process(delta: float) -> void:
	if is_dead and Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
#endregion



	
