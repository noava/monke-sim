extends Control

var is_menu: bool = false
@onready var player: CharacterBody3D = $"../.."

func _ready() -> void:
	hide()
	$Choices.hide()
	$AreYouSure.hide()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc"):
		if !is_menu:
			open_menu()
		else:
			_on_resume_pressed()
			$AreYouSure.hide()

func open_menu():
	show()
	$Choices.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	is_menu = true

func _on_resume_pressed() -> void:
	hide()
	$Choices.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	is_menu = false

func _on_stuck_pressed() -> void:
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(45, -4, 45)
	_on_resume_pressed()

func _on_leave_pressed() -> void:
	$Choices.hide()
	$AreYouSure.show()

# Secondary Menu (Are you sure?)
func _on_no_button_pressed() -> void:
	$Choices.show()
	$AreYouSure.hide()

func _on_yes_button_pressed() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	# TODO: Fix gray screen when host leaves
	get_tree().change_scene_to_file("res://scenes/main_ui.tscn")
