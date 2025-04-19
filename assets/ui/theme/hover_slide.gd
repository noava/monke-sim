extends Node

@export var offset := -15
@export var duration := 0.15

var tween: Tween

func _ready():
	var button := get_parent()
	tween = create_tween()
	tween.kill()

	button.connect("mouse_entered", _on_mouse_entered)
	button.connect("mouse_exited", _on_mouse_exited)

func _on_mouse_entered():
	animate_button_position(-offset)

func _on_mouse_exited():
	animate_button_position(0)

func animate_button_position(target_x: float):
	var button := get_parent()
	tween.kill()
	tween = create_tween()
	tween.tween_property(button, "position:x", target_x, duration)
