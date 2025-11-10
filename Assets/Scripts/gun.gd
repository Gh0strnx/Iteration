extends Node2D

var bulletPrefab = preload("res://Assets/Scenes/bullet.tscn")




func _on_timer_timeout() -> void:
	spawn_bullet()
	

func spawn_bullet():
	var bullet = bulletPrefab.instantiate()
	bullet.position = global_position
	get_tree().root.add_child(bullet)
