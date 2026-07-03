extends CharacterBody2D

# Health
@export_range(0.25, 99999) var health: float = 100
@export_range(0, 100) var LifeSteal: float = 0
@export_range(0, 99999) var Regeneration: float = 0
@export_range(0, 99999) var regenTime: float = 4.0

# Movement
@export_range(0.01, 99999) var speed: float = 7.6

# Block
@export_range(0.05, 99999) var blockCooldown: float = 6
@export var blocking = false
@export var block_cooldown_timer: float = 0.0
@export var block_cooldown_active: bool = false
var canBlockPerm = true

# Audio
@export_range(0.1, 99999) var soundRadius: float = 480
@export_range(0.1, 99999) var volumeIncreaser: float = 0

# Sync
@export var syncedPosition: Vector2 = Vector2.ZERO
@export var colorSetting: String = "WHITE"
var id: int = 0

# State
@export var alive = true
var max_health: float = 0.0
var regen_timer: float = 0.0
var death_processed: bool = false
var currentlyleft = false
var canBlock = true
var currentlyright = true


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
		player_name = "Player " + str((GameManager.Players[id].index) + 1)

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


func update_health_bar() -> void:
	var bar = $"Control/VBoxContainer/ProgressBar"
	bar.max_value = max_health
	bar.value = health


func _physics_process(delta: float) -> void:
	var is_authority := $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()

	if is_authority and alive:
		var direction := Input.get_vector("left", "right", "up", "down")
		velocity = direction * (speed * 100)

		if velocity.length() > 0.0:
			$Sprite.play("run")
		else:
			$Sprite.play("idle")

		var facing_left := get_global_mouse_position().x > global_position.x
		$Sprite.flip_h = facing_left

		if facing_left and currentlyleft == false:
			$Gun.global_position.x += 43.35
			currentlyright = false
			currentlyleft = true

		elif !facing_left and currentlyright == false:
			$Gun.global_position.x -= 43.35
			currentlyleft = false
			currentlyright = true

		move_and_slide()
		syncedPosition = global_position

		regen_timer += delta
		if regen_timer >= regenTime:
			regen_timer = 0.0
			regenerate()

		if block_cooldown_active:
			block_cooldown_timer += delta
			if block_cooldown_timer >= blockCooldown:
				block_cooldown_active = false
				block_cooldown_timer = 0.0

		if Input.is_action_just_pressed("Block") and canBlock and canBlockPerm:
			block()

	else:
		global_position = global_position.lerp(syncedPosition, delta * 10.0)

	update_health_bar()

	if block_cooldown_active:
		$"Control/Anchor/Block".show()
		$"Control/Anchor/Block".max_value = blockCooldown
		$"Control/Anchor/Block".value = block_cooldown_timer
	else:
		$"Control/Anchor/Block".hide()

	$AudioStreamPlayer2D.volume_db = volumeIncreaser
	$AudioStreamPlayer2D.max_distance = soundRadius

	if !alive and !death_processed:
		death_processed = true

		if multiplayer.get_unique_id() == id:
			for node in get_tree().get_nodes_in_group("global_canvas_modulate"):
				node.hide()

		hide()
		$Collision.disabled = true

		if multiplayer.is_server():
			remove_from_group("alivePlayers")
			remove_from_alive_group.rpc()


@rpc("any_peer", "call_local", "reliable")
func remove_from_alive_group():
	remove_from_group("alivePlayers")


@rpc("any_peer", "call_local", "reliable")
func request_hurt_player(damage: float) -> void:
	if not multiplayer.is_server():
		return

	if not alive:
		return

	if blocking:
		return

	health -= damage
	health = snappedf(health, 0.1)

	print("Player health " + str(health), "   NAME: ", name)

	if health <= 0.001:
		health = 0
		alive = false
		GameManager.Players[id].alive = false

	sync_health.rpc(health, alive)


# Keep this old function as a backup so old code does not break.
# But from now on, bullets should use request_hurt_player().
@rpc("any_peer", "call_local", "reliable")
func hurt_player(damage: float) -> void:
	request_hurt_player(damage)


# Server tells everyone the correct health and alive state.
@rpc("any_peer", "call_local", "reliable")
func sync_health(new_health: float, new_alive: bool) -> void:
	health = new_health
	alive = new_alive
	update_health_bar()


func apply_poison(damage_per_second: float, poison_source = null) -> void:
	if not multiplayer.is_server():
		return

	var shooter_id: int = -1
	var lifesteal_amount: float = 0.0

	if poison_source != null:
		shooter_id = int(str(poison_source.name))
		lifesteal_amount = poison_source.LifeSteal

	_run_poison_ticks(damage_per_second, shooter_id, lifesteal_amount)


func _run_poison_ticks(damage_per_second: float, shooter_id: int, lifesteal: float) -> void:
	for i in range(3):
		await get_tree().create_timer(1.0).timeout

		if not alive:
			break

		request_hurt_player(damage_per_second)

		if shooter_id != -1 and lifesteal > 0.0:
			var heal_amount = damage_per_second * (lifesteal / 100.0)
			apply_lifesteal_to_player.rpc_id(shooter_id, heal_amount)


@rpc("any_peer", "call_local", "reliable")
func apply_lifesteal_to_player(amount: float) -> void:
	if not alive:
		return

	health = snappedf(min(health + amount, max_health), 0.1)
	update_health_bar()

	if multiplayer.is_server():
		sync_health.rpc(health, alive)


func block():
	canBlock = false
	blocking = true

	set_outline_rpc.rpc(true)

	$"Control/Anchor/Block".max_value = blockCooldown
	$"Control/Anchor/Block".value = 0.0
	$"Control/Anchor/Block".show()

	block_cooldown_timer = 0.0
	block_cooldown_active = true

	await get_tree().create_timer(0.3).timeout

	blocking = false
	set_outline_rpc.rpc(false)

	await get_tree().create_timer(blockCooldown).timeout

	canBlock = true


func regenerate() -> void:
	if not multiplayer.is_server():
		return

	if health < max_health and alive:
		health = snappedf(min(health + Regeneration, max_health), 0.1)
		update_health_bar()
		sync_health.rpc(health, alive)


func enable_outline(enabled: bool, color: Color = Color.WHITE):
	var actual_color = Color.from_string(colorSetting, Color.WHITE)
	var mat = $Sprite.material as ShaderMaterial
	mat.set_shader_parameter("outline_enabled", enabled)
	mat.set_shader_parameter("outline_color", actual_color)


@rpc("any_peer", "call_local")
func set_outline_rpc(enabled: bool):
	enable_outline(enabled)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullet") and body.get("shooter") == self and body.left == false:
		body.collision_mask = 0


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("bullet") and body.get("shooter") == self:
		body.left = true
		body.collision_mask = 0
		body.set_collision_mask_value(1, true)


@rpc("any_peer", "call_local", "reliable")
func rpc_update_health_bar():
	update_health_bar()
