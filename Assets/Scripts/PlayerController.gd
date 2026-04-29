extends CharacterBody2D

##movement speed of player - IMPLEMENTED
@export_range (0.01, 99999) var speed: float = 7.6
##health of player - IMPLEMENTED
@export_range (0.25, 99999) var health: float = 4
##How far away player can be heard - NOT IMPLEMENTED
@export_range (0.1, 99999) var soundRadius: float = 480
##How loud the player is - IMPLEMENTED
@export_range (0.1, 99999) var volumeIncreaser: float = 0
##How long is the cooldown on blocking -  IMPLEMENTED (KINDA)
@export_range (0.05, 99999) var blockCooldown: float = 5
##How much health do u gain from hurting someone - IMPLEMENTED
@export_range (0, 99999) var LifeSteal: float = 0
##How long it takes to regenerate - MAYBE IMPLEMENTED
@export_range (0,99999) var regenTime: float = 3.0
##Regeneration Amount - MAYBE IMPLEMENTED
@export_range (0, 99999) var Regeneration: float = 0.25

@export var syncedPosition: Vector2 = Vector2.ZERO
##Is player alive
var alive = true
##Can the player block
var canBlock = true
var blocking = false
var id: int = 0
##Regeneration timer current
var regen_timer: float = 0.0
## Flag to ensure dead cleanup only runs once
var death_processed: bool = false
@onready var max_health: float = health

func _ready() -> void:
	id = str(name).to_int()
	var is_local := $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()
	
	#shader stuff
	$Sprite.material = $Sprite.material.duplicate()
	$Sprite2.material = $Sprite2.material.duplicate()
	enable_outline(false)
	
	if GameManager.localPlayer == self:
		$AudioListener2D.current = true
	else:
		$AudioListener2D.current = false
	
	# This only works if the node name is actually the peer id (like "1", "2", etc).
	$MultiplayerSynchronizer.set_multiplayer_authority(id)
	var player_name = GameManager.Players[id].name
	if player_name == null or player_name == "":
		player_name = "Player " + str(id)
	$"Control/VBoxContainer/Label".text = player_name
	$"Control/VBoxContainer/ProgressBar".max_value = max_health
	$"Control/VBoxContainer/ProgressBar".value = max_health
	

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
		if facing_left == true:
			$Control/Anchor/Block.position.x = 20
		else:
			$Control/Anchor/Block.position.x = -60

		move_and_slide()

		# Sync the result after movement
		syncedPosition = global_position
		
		## REGENERATION - only runs when alive and is authority
		regen_timer += delta
		if regen_timer >= regenTime:
			regen_timer = 0.0
			regenerate()
		
		## BLOCK INPUT
		if Input.is_action_just_pressed("Block") && canBlock:
			block()
			
	else:
		# IMPORTANT: assign the lerp result 
		global_position = global_position.lerp(syncedPosition, delta * 10.0)
		
	## SOUND STUFF
	$AudioStreamPlayer2D.volume_db = volumeIncreaser
	$AudioStreamPlayer2D.max_distance = soundRadius
	
	if !alive && !death_processed:
		death_processed = true
		
		for node in get_tree().get_nodes_in_group("global_canvas_modulate"):
			if !GameManager.localPlayer.is_in_group("alivePlayers"):
				node.hide()
		
		hide()
		$Collision.disabled = true
		remove_from_group("alivePlayers")
		
func hurt_player(damage):
	self.health -= damage
	
	print("Player health " + str(health), "   NAME: ", name)
	if health <= 0:
		alive = false
		GameManager.Players[id].alive = false
	$"Control/VBoxContainer/ProgressBar".value = health
		
func block():
	canBlock = false
	blocking = true
	enable_outline(true)
	await get_tree().create_timer(0.3).timeout
	blocking = false
	enable_outline(false)
	await get_tree().create_timer(blockCooldown).timeout
	canBlock = true
		
func regenerate() -> void:
	if health < max_health:
		health = snappedf(min(health + Regeneration, max_health), 0.1)
		$"Control/VBoxContainer/ProgressBar".value = health

func enable_outline(enabled: bool, color: Color = Color.WHITE):
	var mat = $Sprite.material as ShaderMaterial
	mat.set_shader_parameter("outline_enabled", enabled)
	mat.set_shader_parameter("outline_color", color)
	
	var mat2 = $Sprite2.material as ShaderMaterial
	mat2.set_shader_parameter("outline_enabled", enabled)
	mat2.set_shader_parameter("outline_color", color)
