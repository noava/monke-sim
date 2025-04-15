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

# Throw
var throw_force = 20.0

@export var ANIMATIONPLAYER : AnimationPlayer

@onready var armature: Node3D = $player_model
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var input: MultiplayerSynchronizer = $PlayerInput
@onready var raycast: RayCast3D = $"Head/Camera3D/Grab Ray"
@onready var grab_target: Node3D = $"Head/Camera3D/Grab Ray/Grab Target"

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
		
func _set_layer_recursively(node: Node, layer: int) -> void:
	if node is VisualInstance3D:
		node.layers = layer
	for child in node.get_children():
		_set_layer_recursively(child, layer)

func _ready():
	if not is_multiplayer_authority():
		return

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true

	# Hide monkey visuals for local player
	var monkey_visual_root = $player_model/monkey
	if monkey_visual_root:
		_set_layer_recursively(monkey_visual_root, 1 << 2)
		camera.cull_mask &= ~(1 << 2)  # Hide layer 2 for this camera
	
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	# Mouse
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89.9), deg_to_rad(89.9))

func _physics_process(delta):
	if not is_multiplayer_authority(): return

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
	# TODO: Fix Crouch by adding animation and fixing syncing
	#if input.crouching:
		#if !is_crouching:
			#crouch()
	#elif is_crouching:
		#stand_up()
		
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

	# Make monkey face move direction or look direction
	if velocity.length() > 0.1:
		# Face movement direction
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(velocity.x, velocity.z), LERP_VAL)
	else:
		# Face opposite of look direction when idle
		var cam_forward = head.global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		var target_yaw = atan2(cam_forward.x, cam_forward.z) + PI # ← added PI to face opposite
		armature.rotation.y = lerp_angle(armature.rotation.y, target_yaw, LERP_VAL)



	
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
		elif raycast.is_colliding() and raycast.get_collider() is RigidBody3D:
			grab = raycast.get_collider()

	if grab:
		grab.linear_velocity = grab_force * (grab_target.global_position - grab.global_position)

		if Input.is_action_just_pressed("l_mouse"):
			print("Launching")
			var dir = (grab_target.global_position - global_position).normalized()

			grab.apply_impulse(Vector3.ZERO, dir * throw_force)
			release()
	
	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func crouch():
	if not is_crouching:
		is_crouching = true
		ANIMATIONPLAYER.play("Crouch", -1, CROUCH_ANIM_SPEED)

func stand_up():
	is_crouching = false
	ANIMATIONPLAYER.play("Crouch", -1, -CROUCH_ANIM_SPEED, true)
	
func release():
	grab = null
