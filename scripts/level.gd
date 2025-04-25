extends Node3D

const SPAWN_RANDOM := 5.0

func _ready() -> void:
	if not multiplayer.is_server():
		return
		
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	
	for id in multiplayer.get_peers():
		add_player(id)
		
	if not OS.has_feature("dedicated_server"):
		add_player(1)
		
func add_player(id: int):
	var character = preload("res://scenes/player.tscn").instantiate()
	
	character.set_multiplayer_authority(id)

	var pos := Vector2.from_angle(randf() * 2 * PI)
	character.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 0, pos.y * SPAWN_RANDOM * randf())
	
	character.name = str(id)
	# TODO Fix update player names for non hosts. Also add player_display_name variable somehow
	
	$Players.add_child(character, true)
	
	var player_name = "Player " + str(id)
	character.set_player_name(player_name)
	character.rpc("sync_player_name", player_name)
	
	print("Added player:", character.player_name, " at ", character.position)


func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
	
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)
	
