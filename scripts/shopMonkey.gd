extends Node3D  # Or CharacterBody3D or whatever your Monkenk node is

func _ready():
	var anim_player = $AnimationPlayer
	anim_player.play("stand")
	anim_player.pause()
