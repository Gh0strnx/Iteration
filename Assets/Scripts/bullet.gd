extends CharacterBody2D

# Bullet Stats
var damage = 1.0
var speed: float = 14
var bulletSize = 1
var bulletBounces: int = 0
var bulletRange = 3.5
var poison = 0
var explodingBullets = false
var selfDamage = false

# State
var left = false
var dir: float = 0.0
var _exploded = false
var damaged_players := {}

# References
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

	scale.y = bulletSize
	scale.x = bulletSize

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

		if collider.has_method("request_hurt_player"):
			_handle_player_hit(collider, collision)
		else:
			_handle_non_player_hit(collider)

		if bulletBounces <= 0:
			_try_explode_then_free()
		else:
			bulletBounces -= 1
			velocity = velocity.bounce(collision.get_normal())

			if explodingBullets:
				_spawn_bounce_explosion(collision.get_position())


func _handle_player_hit(collider, collision) -> void:
	if not collider.alive:
		return

	if collider.blocking:
		collider.colorSetting = "CYAN"
		collider.enable_outline(true)
		await get_tree().create_timer(0.15).timeout
		collider.colorSetting = "WHITE"
		collider.enable_outline(false)
		return

	if collider == shooter and selfDamage == false:
		return

	var collider_id = int(str(collider.name))

	if damaged_players.has(collider_id):
		return

	damaged_players[collider_id] = true

	# IMPORTANT:
	# Only the host/server applies damage.
	# All other bullet copies are just visual.
	if multiplayer.is_server():
		collider.request_hurt_player(damage)

		if poison > 0:
			collider.apply_poison(damage * (poison / 100.0), shooter)

		if shooter and shooter.LifeSteal > 0:
			var heal_amount = damage * (shooter.LifeSteal / 100.0)
			shooter.apply_lifesteal_to_player(heal_amount)


func _handle_non_player_hit(collider) -> void:
	if collider.has_method("enable_outline") and collider.blocking == true:
		collider.colorSetting = "CYAN"
		collider.enable_outline(true)
		await get_tree().create_timer(0.15).timeout
		collider.colorSetting = "WHITE"
		collider.enable_outline(false)


func DropOff():
	if bulletRange < 3:
		await get_tree().create_timer(bulletRange).timeout
		_try_explode_then_free()


func _try_explode_then_free():
	if _exploded:
		return

	_exploded = true
	set_physics_process(false)
	velocity = Vector2.ZERO

	if is_instance_valid(self):
		var light = $PointLight2D
		var light_pos = light.global_position

		remove_child(light)
		get_tree().root.add_child(light)

		light.global_position = light_pos

		var tween = get_tree().create_tween()
		tween.tween_property(light, "energy", 0.0, 0.3)
		tween.tween_callback(light.queue_free)

	if explodingBullets:
		_spawn_explosion_at(global_position)

	queue_free()


func _spawn_explosion_at(pos: Vector2) -> void:
	var area = $ExplodingBullets.duplicate()
	get_tree().root.add_child(area)
	area.global_position = pos

	var anim = area.get_node("AnimatedSprite2D")
	anim.sprite_frames = anim.sprite_frames.duplicate()
	anim.sprite_frames.set_animation_loop("default", false)
	anim.show()
	anim.play("default")

	anim.animation_finished.connect(func(): area.queue_free(), CONNECT_ONE_SHOT)

	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(area):
			area.queue_free()
	, CONNECT_ONE_SHOT)

	# Only the server applies explosion damage
	if not multiplayer.is_server():
		return

	var explode_damage = damage * 0.5

	area.force_update_transform()
	await get_tree().process_frame

	for body in area.get_overlapping_bodies():
		if not body.has_method("request_hurt_player"):
			continue

		if not body.alive:
			continue

		if body == shooter and not selfDamage:
			continue

		var body_id = int(str(body.name))

		if damaged_players.has(body_id):
			continue

		damaged_players[body_id] = true

		body.request_hurt_player(explode_damage)


func _spawn_bounce_explosion(pos: Vector2) -> void:
	var area = $ExplodingBullets.duplicate()
	get_tree().root.add_child(area)
	area.global_position = pos

	var anim = area.get_node("AnimatedSprite2D")
	anim.sprite_frames = anim.sprite_frames.duplicate()
	anim.sprite_frames.set_animation_loop("default", false)
	anim.show()
	anim.play("default")

	anim.animation_finished.connect(func(): area.queue_free(), CONNECT_ONE_SHOT)

	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(area):
			area.queue_free()
	, CONNECT_ONE_SHOT)

	# Only the server applies explosion damage
	if not multiplayer.is_server():
		return

	var explode_damage = damage * 0.5

	area.force_update_transform()
	await get_tree().process_frame

	for body in area.get_overlapping_bodies():
		if not body.has_method("request_hurt_player"):
			continue

		if not body.alive:
			continue

		if body == shooter and not selfDamage:
			continue

		var body_id = int(str(body.name))

		if damaged_players.has(body_id):
			continue

		damaged_players[body_id] = true

		body.request_hurt_player(explode_damage)
