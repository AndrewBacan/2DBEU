extends Node

@export var lift_height := 48.0
@export var duration := 0.35

var elapsed := 0.0
var active := false

@onready var sprite = $"../Sprite2D"
@onready var shadow = $"../Shadow"

var sprite_origin := Vector2.ZERO
var shadow_scale := Vector2.ONE


func _ready():
	sprite_origin = sprite.position
	shadow_scale = shadow.scale


func launch():
	elapsed = 0
	active = true


func _process(delta):

	if !active:
		return

	elapsed += delta

	var t = clamp(elapsed / duration, 0.0, 1.0)

	# Creates a smooth jump arc
	var height = sin(t * PI) * lift_height

	sprite.position.y = sprite_origin.y - height

	# Shadow grows until midpoint then shrinks
	var scale_amount = 1.0 + (height / lift_height) * 0.35
	shadow.scale = shadow_scale * scale_amount

	if t >= 1.0:
		active = false
		sprite.position = sprite_origin
		shadow.scale = shadow_scale
