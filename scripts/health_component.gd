extends Node3D

@onready var player: CharacterBody3D = $".."

@export var MAX_HEALTH := 10
var health : float

func _ready() -> void:
	health = MAX_HEALTH

@rpc("any_peer")
func receive_damage(damage: int):
	health -= damage
	if health <= 0:
		health = MAX_HEALTH
		death()
		
func death():
	player.position = Vector3.ZERO
