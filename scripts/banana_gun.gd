extends Node

var is_enabled := false

@onready var ANIMATIONPLAYER: AnimationPlayer = $AnimationPlayer
@onready var muzzle_flash: GPUParticles3D = $MuzzleFlash
@onready var banana_gun: Node3D = $"."
@onready var long_raycast: RayCast3D = %"Long Raycast"

# Hitmarker
@onready var HITMARKER : CompressedTexture2D = preload("res://assets/sprites/hitmarker.png")
@onready var hitmarker: TextureRect = %Hitmarker
var tween: Tween = null

var item_data

func _ready():
	banana_gun.visible = false
	hitmarker.modulate.a = 0.0

func _unhandled_input(_event):
	if not is_multiplayer_authority(): return
	
	if not is_enabled: return

	if Input.is_action_just_pressed("l_mouse") and ANIMATIONPLAYER.current_animation != "shoot":
		play_shoot_effects.rpc()
		
		if long_raycast.is_colliding():
			var hit_player = long_raycast.get_collider()
			var health_component = hit_player.get_node_or_null("HealthComponent")

			if health_component:
				health_component.rpc_id(
					hit_player.get_multiplayer_authority(),
					"receive_damage",
					item_data.damage
				)
				show_hitmarker()

# Let other players see you shooting
@rpc("call_local")
func play_shoot_effects():
	ANIMATIONPLAYER.stop()
	ANIMATIONPLAYER.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

# Call from the authority (the owning player)
@rpc("call_local")
func set_enabled(value: bool):
	is_enabled = value
	banana_gun.visible = value

func show_hitmarker():
	if tween: tween.kill()
	hitmarker.modulate.a = 1.0

	tween = create_tween()
	tween.tween_property(hitmarker, "modulate:a", 0.0, 0.3)

func set_item_data(data):
	item_data = data
