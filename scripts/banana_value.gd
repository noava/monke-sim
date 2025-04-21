extends Node

@onready var banana_object: RigidBody3D = $"."

@export var banana_value: int:
	get = get_banana_value

func get_banana_value():
	return banana_value
