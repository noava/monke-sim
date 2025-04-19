extends Control

func _ready() -> void:
	$MainMenu.show()
	$Host.hide()
	$Join.hide()
	$HowToPlay.hide()
	$Credits.hide()
	$HomeBtn.hide()

func _on_host_btn_pressed() -> void:
	$Host.show()
	$MainMenu.hide()
	$HomeBtn.show()

func _on_join_btn_pressed() -> void:
	$Join.show()
	$MainMenu.hide()
	$HomeBtn.show()

func _on_how_to_play_pressed() -> void:
	$HowToPlay.show()
	$MainMenu.hide()
	$HomeBtn.show()
	
func _on_credits_pressed() -> void:
	$Credits.show()
	$MainMenu.hide()
	$HomeBtn.show()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_home_btn_pressed() -> void:
	$MainMenu.show()
	$Host.hide()
	$Join.hide()
	$Credits.hide()
	$HomeBtn.hide()
