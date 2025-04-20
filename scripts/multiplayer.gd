extends Node

const PORT = 135
var peer = ENetMultiplayerPeer.new()
@onready var host_name_entry: LineEdit = %HostNameEntry
@onready var join_name_entry: LineEdit = %JoinNameEntry
@onready var ip_entry: LineEdit = %IPEntry
@onready var join_btn: Button = %JoinBtn
var player_display_name: String = "":
	get: return player_display_name

func _ready() -> void:
	$UI.show()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_pressed() -> void:
	if host_name_entry.text == "":
		OS.alert("Need a name")
		return
		
	player_display_name = host_name_entry.text
	
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	start_game()

func start_game():
	$UI.hide()
	
	if multiplayer.is_server():
		change_level.call_deferred(load("res://scenes/world.tscn"))
		
func change_level(scene: PackedScene):
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
		
	level.add_child(scene.instantiate())


func _on_join_pressed() -> void:
	if join_name_entry.text == "":
		OS.alert("Need a name")
		return
	if ip_entry.text == "":
		OS.alert("Need a remote to connect to.")
		return
	
	player_display_name = join_name_entry.text
	
	peer.create_client(ip_entry.text, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to join. Check IP")
		return
	multiplayer.multiplayer_peer = peer
	start_game()
