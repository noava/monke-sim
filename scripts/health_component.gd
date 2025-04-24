extends Node3D

@onready var player: CharacterBody3D = $".."
@onready var health_bar: TextureProgressBar = $"../HUD/HealthBar"
@onready var max_health: float = health_bar.max_value
@onready var amount: Label = $"../HUD/HealthBar/Amount"
var bar_tween: Tween = null
@onready var death_screen: Control = $"../HUD/DeathScreen"
@onready var bits_and_bobs: Control = $"../HUD/Bits and bobs"

var is_dead: bool = false

var health : float:
	get:
		return health
	set(value):
		health = value
		if health_bar:
			amount.text = str(int(health))
			
			if bar_tween: bar_tween.kill()
			bar_tween = create_tween()
			bar_tween.tween_property(health_bar, "value", health, 0.3)

func _ready() -> void:
	health = max_health
	death_screen.hide()
	bits_and_bobs.show()

@rpc("any_peer")
func receive_damage(damage: int):
	health -= damage
	if health <= 0:
		death()
	
	print("Player %s has %s health" % [player.name, health])

func death():
	# Show Death Screen and Ragdoll
	is_dead = true
	death_screen.show()
	bits_and_bobs.hide()
	health = max_health
	
	print("Player %s has died" % player.name)
	await get_tree().create_timer(1).timeout
	
	player.visible = false
	await get_tree().create_timer(2).timeout
	
	# Tp to spawn and hide Death Screen
	player.position = Vector3.ZERO
	death_screen.hide()
	bits_and_bobs.show()
	
	# Be unvisible for five seconds or until you shoot again.
	await get_tree().create_timer(5).timeout
	health = max_health
	player.visible = true
	is_dead = false
