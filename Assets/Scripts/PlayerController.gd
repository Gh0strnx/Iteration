extends CharacterBody2D

##movement speed of player - IMPLEMENTED
@export_range (0.01, 99999) var speed: float = 7.0
##health of player - IMPLEMENTED
@export_range (0.25, 99999) var health: float = 10.0
##How far away player can be heard - NOT IMPLEMENTED
@export_range (0.1, 99999) var soundRadius: float = 480
##How loud the player is - NOT IMPLEMENTED
@export_range (0.1, 99999) var volumeIncreaser: float = 0
##How long is the cooldown on blocking - NOT IMPLEMENTED
@export_range (0.05, 99999) var blockCooldown: float = 3
##How much health do u gain from hurting someone - NOT IMPLEMENTED
@export_range (0, 99999) var LifeSteal: float = 0
##How much health do u regenerate over time. - NOT IMPLEMENTED
@export_range (0, 99999) var Regeneration: float = 0
@export var syncedPosition: Vector2 = Vector2.ZERO
##Is player alive
var alive = true
##Can the player block
var canBlock = true

func _ready() -> void:
	var is_local := $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()
	
	if GameManager.localPlayer == self:
		$AudioListener2D.current = true
	else:
		$AudioListener2D.current = false
	
	# This only works if the node name is actually the peer id (like "1", "2", etc).
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	

func _physics_process(delta: float) -> void:
	var is_authority := $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()

	if is_authority && alive:
		var direction := Input.get_vector("left", "right", "up", "down")
		velocity = direction * (speed * 100)

		if velocity.length() > 0.0:
			$Sprite.play("run")
			$Sprite2.play("run")
			if !$AudioStreamPlayer2D.playing:
				$AudioStreamPlayer2D.play()
		else:
			$Sprite.play("idle")
			$Sprite2.play("idle")
			if $AudioStreamPlayer2D.playing:
				$AudioStreamPlayer2D.stop()
		var facing_left := get_global_mouse_position().x < global_position.x
		$Sprite.flip_h = facing_left
		$Sprite2.flip_h = facing_left

		move_and_slide()

		# Sync the result after movement
		syncedPosition = global_position
	else:
		# IMPORTANT: assign the lerp result 
		global_position = global_position.lerp(syncedPosition, delta * 10.0)
		
	## SOUND STUFF
	$AudioStreamPlayer2D.volume_db = volumeIncreaser
	$AudioStreamPlayer2D.max_distance = soundRadius
		
	
	if !alive:
		GameManager.localPlayer = null
	
		for node in get_tree().get_nodes_in_group("global_canvas_modulate"):
			node.hide()
		
		$Sprite.hide()
		$Sprite2.hide()
		$Gun.hide()
		$LightMoving.hide()
		$Collision.disabled = true
		remove_from_group("alivePlayers")
		
	if Input.is_action_pressed("Block"):
		pass
	
func hurt_player(damage):
	GameManager.localPlayer.health -= damage
	print("Player health" + str(health))
	if health <= 0:
		alive = false
		pass

		
