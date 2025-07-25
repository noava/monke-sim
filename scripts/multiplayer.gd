extends Node

const PORT = 8698
var peer = ENetMultiplayerPeer.new()
var level_scene = preload("res://scenes/world.tscn")
@onready var host_name_entry: LineEdit = %HostNameEntry
@onready var join_name_entry: LineEdit = %JoinNameEntry
@onready var ip_entry: LineEdit = %IPEntry
@onready var join_btn: Button = %JoinBtn
var player_display_name: String = "":
	get: return player_display_name

func _ready() -> void:
	$UI.show()
	
	if "--server" in OS.get_cmdline_args():
		peer.create_server(PORT)
		start_game()
		print("Server started")

func _on_host_pressed() -> void:
	if host_name_entry.text == "":
		OS.alert("Need a name")
		return
		
	player_display_name = host_name_entry.text
	
	peer.create_server(PORT)
	start_game()

func start_game():
	$UI.hide()
	multiplayer.multiplayer_peer = peer
	
	if multiplayer.is_server():
		change_level.call_deferred(level_scene)
		
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
	start_game()

func _on_public_server_btn_pressed() -> void:
	ip_entry.text = "monke-sim-server.noava.dev"
	
	peer.create_client(ip_entry.text, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Public Server down at the moment")
		return
	start_game()
