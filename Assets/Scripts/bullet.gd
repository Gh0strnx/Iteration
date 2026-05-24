extends CharacterBody2D
var selfDamage = true
var damage = 1.0
var speed: float = 10.5
var bulletBounces: int = 0
var bulletRange = 3.5
var poison = 0
var bulletSize = 1
var dir: float = 0.0
var shooter = null
func start(_position: Vector2, _direction: float) -> void:
	position = _position
	dir = _direction
	velocity = Vector2.RIGHT.rotated(dir) * (speed * 100)
	self.scale.y = bulletSize
	self.scale.x = bulletSize
func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.has_method("hurt_player") && collider.blocking == false:
			var hit_player_id = int(str(collider.name))
			if multiplayer.get_unique_id() == hit_player_id:
				if collider.name == GameManager.localPlayer.name:
					if selfDamage == true:
						collider.hurt_player(damage)
						if poison > 0:
							collider.apply_poison(damage * (poison / 100.0))
						if shooter && shooter.LifeSteal > 0:
							shooter.health = snappedf(min(shooter.health + (damage * (shooter.LifeSteal / 100.0)), shooter.max_health), 0.1)
							shooter.get_node("Control/VBoxContainer/ProgressBar").value = shooter.health
				else:
					collider.hurt_player(damage)
					if poison > 0:
						collider.apply_poison(damage * (poison / 100.0))
					if shooter && shooter.LifeSteal > 0:
						shooter.health = snappedf(min(shooter.health + (damage * (shooter.LifeSteal / 100.0)), shooter.max_health), 0.1)
						shooter.get_node("Control/VBoxContainer/ProgressBar").value = shooter.health
		else:
			if collider.has_method("enable_outline") && collider.blocking == true:
				collider.colorSetting = "CYAN"
				collider.enable_outline(true)
				await get_tree().create_timer(0.15).timeout
				collider.colorSetting = "WHITE"
				collider.enable_outline(false)
		if bulletBounces <= 0:
			queue_free()
		else:
			bulletBounces -= 1
			velocity = velocity.bounce(collision.get_normal())
func DropOff():
	if bulletRange < 3.5:
		await get_tree().create_timer(bulletRange).timeout
		queue_free()
