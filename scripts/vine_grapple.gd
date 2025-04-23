extends Node3D

var is_enabled := false

@onready var vine_grapple: Node3D = $"."

func _ready() -> void:
	vine_grapple.visible = false
	

@rpc("call_local")
func set_enabled(value: bool):
	is_enabled = value
	vine_grapple.visible = value
