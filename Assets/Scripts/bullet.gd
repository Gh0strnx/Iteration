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
		if collision.get_collider().has_method("hurt_player") && collision.get_collider().blocking == false:
			print(GameManager.localPlayer.name)
			if collision.get_collider().name == GameManager.localPlayer.name:
				if selfDamage == true:
					collision.get_collider().hurt_player(damage)
					if poison > 0:
						collision.get_collider().apply_poison(damage * (poison / 100.0))
					if shooter && shooter.LifeSteal > 0:
						shooter.health = snappedf(min(shooter.health + (damage * (shooter.LifeSteal / 100.0)), shooter.max_health), 0.1)
						shooter.get_node("Control/VBoxContainer/ProgressBar").value = shooter.health
					queue_free()
			else:
				collision.get_collider().hurt_player(damage)
				if poison > 0:
					collision.get_collider().apply_poison(damage * (poison / 100.0))
				if shooter && shooter.LifeSteal > 0:
					shooter.health = snappedf(min(shooter.health + (damage * (shooter.LifeSteal / 100.0)), shooter.max_health), 0.1)
					shooter.get_node("Control/VBoxContainer/ProgressBar").value = shooter.health
				queue_free()

		else:
			if collision.get_collider().has_method("enable_outline") && collision.get_collider().blocking == true:
				collision.get_collider().colorSetting = "CYAN"
				collision.get_collider().enable_outline(true)
				await get_tree().create_timer(0.15).timeout
				collision.get_collider().colorSetting = "WHITE"
				collision.get_collider().enable_outline(false)

		if bulletBounces != -1:
			velocity = velocity.bounce(collision.get_normal())
			bulletBounces = bulletBounces - 1

		if bulletBounces == -1:
			queue_free()

func DropOff():
	if bulletRange < 3.5:
		await get_tree().create_timer(bulletRange).timeout
		queue_free()
