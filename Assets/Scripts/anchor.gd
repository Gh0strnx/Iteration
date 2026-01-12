extends Node2D

func _process(_delta: float) -> void:
	work.rpc()

@rpc("any_peer","call_local")
func work():
	
	var aim_dir: Vector2 = get_global_mouse_position() - global_position
	if aim_dir == Vector2.ZERO:
		aim_dir = Vector2.RIGHT

	rotation = aim_dir.angle()

	var deg := wrapf(rad_to_deg(rotation), -180.0, 180.0)
	$Sprite2D.flip_v = not (deg > -90.0 and deg < 90.0)
