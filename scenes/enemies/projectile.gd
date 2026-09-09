extends Area2D

@export var speed: float = 300.0
@export var damage: int = 8
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func launch(dir: Vector2) -> void:
	direction = dir.normalized()
	
func _on_area_entered(area: Area2D) -> void:
	print("Projectile hit area: ", area.name, " owner: ", area.get_parent().name)
	var hit_owner = area.get_parent()
	if hit_owner.is_in_group("player"):
		if hit_owner.has_method("take_damage"):
			hit_owner.take_damage(damage, direction, 150.0)
		queue_free()
	
