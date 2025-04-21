extends Node3D

var moon_distance := 1000.0
var is_night := false

func _process(_delta):
	var sun_dir = $DirectionalLight3D.global_transform.basis.z.normalized()
	var moon_pos = -sun_dir * moon_distance
	$Moon.global_transform.origin = global_transform.origin + moon_pos

	# Check if the sun is below the horizon
	var now_night = sun_dir.y < 0.0

	# Only trigger when night STARTS
	if now_night and not is_night:
		is_night = true
		print("🌙 Night started! Starting timer.")
		$NightTimer.start()

	# Only trigger when night ENDS
	elif not now_night and is_night:
		is_night = false
		print("🌞 Day started!")

func _on_NightTimer_timeout():
	print("⏰ Night timer ended! Time's up.")
	# You can trigger your purge mode end here
