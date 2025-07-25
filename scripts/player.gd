extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const CROUCH_SPEED = 3.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.0
const SENSITIVITY = 0.004
const LERP_VAL = .15

# Bob
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

# FOV
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Crouch
var is_crouching = false
@export_range(5, 10, 0.1) var CROUCH_ANIM_SPEED : float = 7.0

var gravity = 9.8

# Grab
@export var grab_force = 10
@export var release_force = 0.4
var grab:RigidBody3D
var label_instance: Label3D
var current_target: Node3D = null

# Throw
var throw_force = 20.0

# Hold
@export var is_holding: bool = false

# Crosshair
@onready var HOOK_AVAILIBLE_TEXTURE : CompressedTexture2D = preload("res://assets/sprites/hook_available.png")
@onready var HOOK_NOT_AVAILIBLE_TEXTURE : CompressedTexture2D = preload("res://assets/sprites/crosshair.png")
@onready var crosshair: TextureRect = $HUD/Crosshair

# Animations
@onready var anim_tree: AnimationTree = $player_model/AnimationTree
@onready var camera_animation_player: AnimationPlayer = $Head/CameraAnimationPlayer

enum {IDLE, WALK, RUN, JUMP, HOLD, CROUCH, DEAD}
@export var curAnim: int = IDLE

@export var blend_speed = 15

var walk_val = 0
var jump_val = 0
var hold_val = 0
var crouch_val = 0

@onready var player_model: Node3D = $player_model
@onready var player_mesh: MeshInstance3D = $player_model/rig/Skeleton3D/Geo_Chimpanzee
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var input: MultiplayerSynchronizer = $PlayerInput
@onready var grab_raycast: RayCast3D = $"Head/Camera3D/Grab Ray"
@onready var grab_target: Node3D = $"Head/Camera3D/Grab Ray/Grab Target"
@onready var hook_raycast: RayCast3D = %"Long Raycast"
@onready var hook_controller: HookController = $HookController
@onready var health_component: Node3D = %HealthComponent
@onready var name_label_3d: Label3D = %NameLabel3D

var player_name: String = "Unnamed":
	set = set_player_name, get = get_player_name

func set_player_name(value):
	if value != "":
		player_name = value
		if name_label_3d:
			name_label_3d.text = player_name

func get_player_name():
	return player_name

@rpc("any_peer")
func sync_player_name(name: String):
	set_player_name(name)


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
		
func _ready():
	if not is_multiplayer_authority(): return
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	# Player cant see themselves. Only their shadow
	player_mesh.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	# Mouse
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89.9), deg_to_rad(89.9))
		
	player_model.rotation.y = head.rotation.y + PI

func _physics_process(delta):
	handle_animations(delta)

	if not is_multiplayer_authority(): return
	
	update_animation_states()

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if input.jumping and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	input.jumping = false

	# Sprint
	if Input.is_action_pressed("sprint") and not is_crouching:
		speed = SPRINT_SPEED
	elif is_crouching:
		speed = CROUCH_SPEED
	else:
		speed = WALK_SPEED

	# Crouch
	is_crouching = input.crouching
	if is_crouching:
		camera_animation_player.stop()
		camera_animation_player.play("camera_crouch", -1, -1, true)
	else:
		camera_animation_player.stop()
		camera_animation_player.play("camera_crouch", -1, 1)
		
	# Movement/Deceleration.
	var direction = (head.transform.basis * transform.basis * Vector3(input.input_direction.x, 0, input.input_direction.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	# Grab
	if Input.is_action_just_pressed("interact"):
		if grab:
			release()
		elif grab_raycast.is_colliding() and grab_raycast.get_collider() is RigidBody3D and grab_raycast.get_collider().has_node("Grabbable"):
			grab = grab_raycast.get_collider()

	if grab and not grab.has_method("get_banana_value"):
		grab.linear_velocity = grab_force * (grab_target.global_position - grab.global_position)

		if Input.is_action_just_pressed("l_mouse"):
			print("Launching")
			var dir = (grab_target.global_position - global_position).normalized()

			grab.apply_impulse(Vector3.ZERO, dir * throw_force)
			release()
	
	# Show Interact Label
	if grab_raycast.is_colliding() and grab_raycast.get_collider() is Node3D and not grab:
		var target = grab_raycast.get_collider()
		
		if target != current_target:
			remove_existing_labels()
			current_target = target

			# Check if the label already exists
			if not target.has_node("LookLabel"):
				# Create the label
				label_instance = Label3D.new()
				label_instance.name = "LookLabel"
				label_instance.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label_instance.position = Vector3(0, 0.1, 0)
				
				# Label Color
				label_instance.modulate = Color("#F6D9BC")
				
				if target.has_method("get_item_price"):
					var price = target.item_price
					label_instance.modulate = Color("#8D1A00")
					label_instance.text = "-" + str(price) + " bananas"
				elif target.has_method("get_banana_value"):
					var banana_value = target.banana_value
					label_instance.position = Vector3(0, 0.4, 0)
					label_instance.text = "+" + str(banana_value) + " bananas"
				elif target.has_node("Grabbable"):
					label_instance.text = "uppies"
				
				target.add_child(label_instance)
	else:
		remove_existing_labels()
		current_target = null

	move_and_slide()
	
	crosshair.texture = HOOK_AVAILIBLE_TEXTURE if hook_raycast.is_colliding() and not hook_controller.is_hook_launched and hook_controller.is_enabled else HOOK_NOT_AVAILIBLE_TEXTURE


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

	
func release():
	grab = null

func remove_existing_labels():
	if label_instance and label_instance.is_inside_tree():
		label_instance.queue_free()
		label_instance = null

@rpc("call_local")
func set_holditem_enabled(value: bool):
	is_holding = value

func handle_animations(delta):
	match curAnim:
		IDLE:
			walk_val = lerpf(walk_val, 0, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
			hold_val = lerpf(hold_val, 0, blend_speed * delta)
			crouch_val = lerpf(crouch_val, 0, blend_speed * delta)
		WALK:
			walk_val = lerpf(walk_val, 1, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
			hold_val = lerpf(hold_val, 0, blend_speed * delta)
			crouch_val = lerpf(crouch_val, 0, blend_speed * delta)

		RUN:
			walk_val = lerpf(clamp(walk_val * 2.0, 0.0, 3.0), 1.0, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
			hold_val = lerpf(hold_val, 0, blend_speed * delta)
			crouch_val = lerpf(crouch_val, 0, blend_speed * delta)
		JUMP:
			walk_val = lerpf(walk_val, 0, blend_speed * delta)
			jump_val = lerpf(jump_val, 1, blend_speed * delta)
			hold_val = lerpf(hold_val, 0, blend_speed * delta)
			crouch_val = lerpf(crouch_val, 0, blend_speed * delta)
		HOLD:
			walk_val = lerpf(walk_val, 0, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
			hold_val = lerpf(hold_val, 1, blend_speed * delta)
			crouch_val = lerpf(crouch_val, 0, blend_speed * delta)
		CROUCH:
			if input.input_direction.length() > 0.1:
				walk_val = lerpf(walk_val, 1, blend_speed * delta)
				crouch_val = lerpf(crouch_val, 0.7, blend_speed * delta)
			else:
				walk_val = lerpf(walk_val, 0, blend_speed * delta)
				crouch_val = lerpf(crouch_val, 1, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
			hold_val = lerpf(hold_val, 0, blend_speed * delta)
		DEAD:
			walk_val = lerpf(walk_val, 0, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
			hold_val = lerpf(hold_val, 0, blend_speed * delta)
			crouch_val = lerpf(clamp(crouch_val * 1.3, 0.0, 6.0), 1, blend_speed * delta)
	update_tree()

func update_tree():
	anim_tree["parameters/Walk/blend_amount"] = walk_val
	anim_tree["parameters/Jump/blend_amount"] = jump_val
	anim_tree["parameters/Hold/blend_amount"] = hold_val
	anim_tree["parameters/Crouch/blend_amount"] = crouch_val

func update_animation_states():
	if health_component.is_dead:
		curAnim = DEAD
	elif is_on_floor():
		if input.input_direction.length() > 0.1:
			if speed == WALK_SPEED:
				curAnim = WALK
			if speed == SPRINT_SPEED:
				curAnim = RUN
		elif is_holding:
			curAnim = HOLD
		else:
			curAnim = IDLE
		if is_crouching:
			curAnim = CROUCH
	else:
		curAnim = JUMP
