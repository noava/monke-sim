extends Node

const PORT = 135
var peer = ENetMultiplayerPeer.new()
@onready var name_entry: LineEdit = %NameEntry
@onready var ip_entry: LineEdit = %IPEntry
@onready var join_btn: Button = %JoinBtn

func _ready() -> void:
	# wait for text input
	join_btn.disabled = true
	ip_entry.text_changed.connect(_on_text_changed)
	
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_pressed() -> void:
	if name_entry.text == "":
		OS.alert("Need a name")
		return

	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	start_game()

func start_game():
	$UI.hide()
	
	if multiplayer.is_server():
		change_level.call_deferred(load("res://scenes/testing.tscn"))
		
func change_level(scene: PackedScene):
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
		
	level.add_child(scene.instantiate())

func _on_text_changed(new_text):
	join_btn.disabled = new_text.strip_edges() == ""

func _on_join_pressed() -> void:
	if name_entry.text == "":
		OS.alert("Need a name")
		return
	if ip_entry.text == "":
		OS.alert("Need a remote to connect to.")
		return
	peer.create_client(ip_entry.text, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to join. Check IP")
		return
	multiplayer.multiplayer_peer = peer
	start_game()
