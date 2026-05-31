extends CharacterBody2D
#Bullet Stats
var damage = 1.0
var speed: float = 10.5
var bulletSize = 1
var bulletBounces: int = 0
var bulletRange = 3.5
var poison = 0
var explodingBullets = false
var selfDamage = true

#State
var left = false
var dir: float = 0.0
var _exploded = false

#References
var shooter = null
var explosion_scene = preload("res://Assets/Scenes/explosion.tscn")


func start(_position: Vector2, _direction: float) -> void:
	collision_layer = 0
	set_collision_layer_value(4, true)
	collision_mask = 0
	set_collision_mask_value(4, true)
	position = _position
	dir = _direction
	velocity = Vector2.RIGHT.rotated(dir) * (speed * 100)
	self.scale.y = bulletSize
	self.scale.x = bulletSize
	var anim = $ExplodingBullets/AnimatedSprite2D
	anim.hide()
	anim.stop()
	DropOff()

func _physics_process(delta):
	if _exploded:
		return
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.has_method("hurt_player") && collider.blocking == false:
			if not collider.alive:
				if bulletBounces <= 0:
					_try_explode_then_free()
				else:
					bulletBounces -= 1
					velocity = velocity.bounce(collision.get_normal())
					if explodingBullets:
						_spawn_bounce_explosion(collision.get_position())
				return
			var hit_player_id = int(str(collider.name))
			if multiplayer.get_unique_id() == hit_player_id:
				if collider.name == GameManager.localPlayer.name:
					if selfDamage == true:
						collider.hurt_player(damage)
						if poison > 0:
							collider.apply_poison(damage * (poison / 100.0), shooter)
						if shooter && shooter.LifeSteal > 0:
							shooter.health = snappedf(min(shooter.health + (damage * (shooter.LifeSteal / 100.0)), shooter.max_health), 0.1)
							shooter.get_node("Control/VBoxContainer/ProgressBar").value = shooter.health
				else:
					collider.hurt_player(damage)
					if poison > 0:
						collider.apply_poison(damage * (poison / 100.0), shooter)
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
			_try_explode_then_free()
		else:
			bulletBounces -= 1
			velocity = velocity.bounce(collision.get_normal())
			if explodingBullets:
				_spawn_bounce_explosion(collision.get_position())

func DropOff():
	if bulletRange < 3.5:
		await get_tree().create_timer(bulletRange).timeout
		_try_explode_then_free()

func _try_explode_then_free():
	if _exploded:
		return
	_exploded = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	if explodingBullets:
		_do_explosion()
		await get_tree().create_timer(0.43).timeout
	if is_instance_valid(self):
		var light = $PointLight2D
		var light_pos = light.global_position
		get_tree().root.add_child(light)
		light.global_position = light_pos
		var tween = get_tree().create_tween()
		tween.tween_property(light, "energy", 0.0, 0.3)
		tween.tween_callback(light.queue_free)
		queue_free()

func _do_explosion() -> void:
	var anim = $ExplodingBullets/AnimatedSprite2D
	anim.show()
	anim.play("default")
	if shooter == null:
		return
	var shooter_peer_id = int(str(shooter.name))
	if multiplayer.get_unique_id() != shooter_peer_id:
		return
	var explode_area = $ExplodingBullets
	explode_area.force_update_transform()
	await get_tree().process_frame
	var explode_damage = damage * 0.5
	for body in explode_area.get_overlapping_bodies():
		if not body.has_method("hurt_player"):
			continue
		if not body.alive:
			continue
		if body.name == GameManager.localPlayer.name and not selfDamage:
			continue
		var hit_player_id = int(str(body.name))
		_apply_explosion_damage.rpc_id(hit_player_id, explode_damage)

func _spawn_bounce_explosion(pos: Vector2) -> void:
	var area = $ExplodingBullets.duplicate()
	get_tree().root.add_child(area)
	area.global_position = pos

	var anim = area.get_node("AnimatedSprite2D")
	anim.show()
	anim.play("default")

	if shooter == null:
		await get_tree().create_timer(0.5).timeout
		area.queue_free()
		return

	var shooter_peer_id = int(str(shooter.name))
	if multiplayer.get_unique_id() != shooter_peer_id:
		await get_tree().create_timer(0.5).timeout
		area.queue_free()
		return

	var explode_damage = damage * 0.5
	area.force_update_transform()
	await get_tree().process_frame

	for body in area.get_overlapping_bodies():
		if not body.has_method("hurt_player"):
			continue
		if not body.alive:
			continue
		if body.name == GameManager.localPlayer.name and not selfDamage:
			continue
		var hit_player_id = int(str(body.name))
		_apply_explosion_damage.rpc_id(hit_player_id, explode_damage)

	await get_tree().create_timer(0.5).timeout
	area.queue_free()

@rpc("any_peer", "call_local")
func _apply_explosion_damage(explode_damage: float) -> void:
	var local_player = GameManager.localPlayer
	if not local_player.has_method("hurt_player"):
		return
	if not local_player.alive:
		return
	local_player.hurt_player(explode_damage)
