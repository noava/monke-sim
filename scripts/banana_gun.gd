extends Node

var is_enabled := false

var ANIMATIONPLAYER: AnimationPlayer = null
var muzzle_flash: GPUParticles3D = null
@onready var weapons_holder: Node3D = $"."
@onready var long_raycast: RayCast3D = %"Long Raycast"

# Hitmarker
@onready var HITMARKER : CompressedTexture2D = preload("res://assets/sprites/hitmarker.png")
@onready var hitmarker: TextureRect = %Hitmarker

var tween: Tween = null
var item_data: ItemData
var active_gun: Node3D = null

func _ready():
	for gun in weapons_holder.get_children():
		gun.visible = false
	hitmarker.modulate.a = 0.0

func _unhandled_input(_event):
	if not is_multiplayer_authority(): return
	if not is_enabled: return
	if Input.is_action_just_pressed("l_mouse") and ANIMATIONPLAYER and ANIMATIONPLAYER.current_animation != "shoot":
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

@rpc("call_local")
func play_shoot_effects():
	if ANIMATIONPLAYER:
		ANIMATIONPLAYER.stop()
		ANIMATIONPLAYER.play("shoot")
	if muzzle_flash:
		muzzle_flash.restart()
		muzzle_flash.emitting = true

@rpc("call_local")
func set_enabled(value: bool):
	is_enabled = value
	if active_gun:
		active_gun.visible = value

func show_hitmarker():
	if tween: tween.kill()
	hitmarker.modulate.a = 1.0

	tween = create_tween()
	tween.tween_property(hitmarker, "modulate:a", 0.0, 0.3)

func set_item_data(data):
	item_data = data
	set_weapon.rpc(item_data.name)
	set_weapon(item_data.name)
	
@rpc("any_peer")
func set_weapon(weapon_name: String):
	for gun in weapons_holder.get_children():
		var should_activate = gun.name == weapon_name
		gun.visible = should_activate
		if should_activate:
			active_gun = gun
			ANIMATIONPLAYER = gun.get_node_or_null("AnimationPlayer")
			muzzle_flash = gun.get_node_or_null("MuzzleFlash")
