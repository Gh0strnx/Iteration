extends CharacterBody2D

@export var speed := 700.0
@export var health := 10.0
@export var soundRadius = 0
@export var volume = 0
@export var blockCooldown = 3
@export var syncedPosition: Vector2 = Vector2.ZERO
var alive = true
var canBlock = true

func _ready() -> void:
	
	# This only works if the node name is actually the peer id (like "1", "2", etc).
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	

func _physics_process(delta: float) -> void:
	var is_authority := $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()

	if is_authority && alive:
		var direction := Input.get_vector("left", "right", "up", "down")
		velocity = direction * speed

		if velocity.length() > 0.0:
			$Sprite.play("run")
			$Sprite2.play("run")
		else:
			$Sprite.play("idle")
			$Sprite2.play("idle")

		var facing_left := get_global_mouse_position().x < global_position.x
		$Sprite.flip_h = facing_left
		$Sprite2.flip_h = facing_left

		move_and_slide()

		# Sync the result after movement
		syncedPosition = global_position
	else:
		# IMPORTANT: assign the lerp result 
		global_position = global_position.lerp(syncedPosition, delta * 10.0)
	
	if !alive:
		GameManager.localPlayer = null
	
		for node in get_tree().get_nodes_in_group("global_canvas_modulate"):
			node.hide()
		
		$Sprite.hide()
		$Sprite2.hide()
		$Gun.hide()
		$LightMoving.hide()
		$Collision.disabled = true
	
func hurt_player(damage):
	GameManager.localPlayer.health -= damage
	print(health)
	if health <= 0:
		alive = false
		pass

		
