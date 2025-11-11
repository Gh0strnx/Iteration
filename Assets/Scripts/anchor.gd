extends Node2D

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	#print(global_rotation_degrees)
	if global_rotation_degrees > -90 && global_rotation_degrees < 90:
		$Gun/Sprite2D.flip_v = false
	else:
		$Gun/Sprite2D.flip_v = true
