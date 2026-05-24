extends CharacterBody2D

@export_range (0.01, 99999) var speed: float = 7.6
@export_range (0.25, 99999) var health: float = 100
@export_range (0.1, 99999) var soundRadius: float = 480
@export_range (0.1, 99999) var volumeIncreaser: float = 0
@export_range (0.05, 99999) var blockCooldown: float = 6
@export_range (0, 100) var LifeSteal: float = 0
@export_range (0,99999) var regenTime: float = 4.0
@export_range (0, 99999) var Regeneration: float = 0
@export var colorSetting: String = "WHITE"
@export var syncedPosition: Vector2 = Vector2.ZERO
@export var alive = true
var canBlock = true
@export var blocking = false
var id: int = 0
var regen_timer: float = 0.0
var death_processed: bool = false
var block_cooldown_timer: float = 0.0
var block_cooldown_active: bool = false
var max_health: float = 0.0

func _ready() -> void:
	max_health = health
	id = str(name).to_int()
	$MultiplayerSynchronizer.set_multiplayer_authority(id)
	$Sprite.material = $Sprite.material.duplicate()
	enable_outline(false)

	if GameManager.localPlayer == self:
		$AudioListener2D.current = true
	else:
		$AudioListener2D.current = false

	var player_name = GameManager.Players[id].name
	if player_name == null or player_name == "":
		player_name = "Player " + str(id)
	$"Control/VBoxContainer/Label".text = player_name
	$"Control/VBoxContainer/ProgressBar".max_value = max_health
	$"Control/VBoxContainer/ProgressBar".value = max_health
	$"Control/Anchor/Block".hide()
	$"Control/Anchor/Block".max_value = blockCooldown
	$"Control/Anchor/Block".value = blockCooldown

func apply_player_colour():
	var hex = GameManager.Players[id].get("hex", "ffffff")
	var colour = Color("#" + hex)
	var mat = $Sprite.material as ShaderMaterial
	mat.set_shader_parameter("player_color", colour)

func update_health_bar():
	$"Control/VBoxContainer/ProgressBar".value = health

func _physics_process(delta: float) -> void:
	var is_authority := $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()

	if is_authority && alive:
		var direction := Input.get_vector("left", "right", "up", "down")
		velocity = direction * (speed * 100)

		if velocity.length() > 0.0:
			$Sprite.play("run")
			if !$AudioStreamPlayer2D.playing:
				$AudioStreamPlayer2D.play()
		else:
			$Sprite.play("idle")
			if $AudioStreamPlayer2D.playing:
				$AudioStreamPlayer2D.stop()

		var facing_left := get_global_mouse_position().x > global_position.x
		$Sprite.flip_h = facing_left

		move_and_slide()
		syncedPosition = global_position

		regen_timer += delta
		if regen_timer >= regenTime:
			regen_timer = 0.0
			regenerate()

		if block_cooldown_active:
			block_cooldown_timer += delta
			$"Control/Anchor/Block".value = block_cooldown_timer
			if block_cooldown_timer >= blockCooldown:
				block_cooldown_active = false
				block_cooldown_timer = 0.0
				$"Control/Anchor/Block".hide()

		if Input.is_action_just_pressed("Block") && canBlock:
			block()

	else:
		global_position = global_position.lerp(syncedPosition, delta * 10.0)
		update_health_bar()

	$AudioStreamPlayer2D.volume_db = volumeIncreaser
	$AudioStreamPlayer2D.max_distance = soundRadius

	if !alive && !death_processed:
		death_processed = true
	
		if multiplayer.get_unique_id() == id:
			for node in get_tree().get_nodes_in_group("global_canvas_modulate"):
				node.hide()
		hide()
		$Collision.disabled = true
		request_remove_from_alive.rpc_id(1)
		
@rpc("any_peer", "call_remote")
func request_remove_from_alive():
	remove_from_group("alivePlayers")

func hurt_player(damage):
	health -= damage
	update_health_bar()
	print("Player health " + str(health), "   NAME: ", name)
	if health <= 0.001:
		alive = false
		GameManager.Players[id].alive = false

func apply_poison(damage_per_second: float) -> void:
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if alive:
			hurt_player(damage_per_second)

func block():
	canBlock = false
	blocking = true
	enable_outline(true)
	$"Control/Anchor/Block".max_value = blockCooldown
	$"Control/Anchor/Block".value = 0.0
	$"Control/Anchor/Block".show()
	block_cooldown_timer = 0.0
	block_cooldown_active = true
	await get_tree().create_timer(0.3).timeout
	blocking = false
	enable_outline(false)
	await get_tree().create_timer(blockCooldown).timeout
	canBlock = true

func regenerate() -> void:
	if health < max_health:
		health = snappedf(min(health + Regeneration, max_health), 0.1)
		update_health_bar()

func enable_outline(enabled: bool, color: Color = Color.WHITE):
	var actual_color = Color.from_string(colorSetting, Color.WHITE)
	var mat = $Sprite.material as ShaderMaterial
	mat.set_shader_parameter("outline_enabled", enabled)
	mat.set_shader_parameter("outline_color", actual_color)
