extends Node3D

@onready var banana_scene: PackedScene = preload("res://scenes/collect_banana.tscn")
@onready var spawn_point: Node3D = $SpawnPoint
@export var spawn_interval: float = 5.0

func _ready():
	call_deferred("spawn_banana")
	
	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(spawn_banana)
	add_child(timer)

func spawn_banana():
	if not is_inside_tree() or not banana_scene:
		return

	var banana = banana_scene.instantiate()

	var spawn_origin: Vector3
	if spawn_point and spawn_point.is_inside_tree():
		spawn_origin = spawn_point.global_transform.origin
	else:
		spawn_origin = global_transform.origin

	banana.transform.origin = spawn_origin

	get_tree().current_scene.call_deferred("add_child", banana)
