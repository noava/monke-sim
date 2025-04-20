extends Node3D

@onready var player: CharacterBody3D = $".."
@onready var health_bar: ProgressBar = $"../HUD/HealthBar"
@onready var max_health: float = health_bar.max_value

var health : float:
	get:
		return health
	set(value):
		health = value
		print(health)
		health_bar.value = health

func _ready() -> void:
	health = max_health

@rpc("any_peer")
func receive_damage(damage: int):
	health -= damage
	if health <= 0:
		death()
	
	print("Player %s has %s health" % [player.name, health])

func death():
	player.position = Vector3.ZERO
	
	health = max_health
	print("Player %s has died" % player.name)
