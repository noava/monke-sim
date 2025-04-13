extends MultiplayerSynchronizer

@export var jumping := false
@export var input_direction := Vector2()
@export var crouching := false

func _ready() -> void:
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())

func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if Input.is_action_just_pressed("jump"):
		jump.rpc()
		
	if Input.is_action_pressed("crouch"):
		if not crouching:
			set_crouching.rpc(true)
	elif crouching:
		set_crouching.rpc(false)
	

@rpc("call_local")
func jump():
	jumping = true

@rpc("call_local")
func set_crouching(state: bool):
	crouching = state
