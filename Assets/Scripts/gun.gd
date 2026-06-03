extends Node2D
#Bullet Stats
@export_range (0.25, 99999) var damage: float = 34
@export_range (0.05, 99999) var speed: float = 14
@export_range (0.25, 99999) var bulletSize: float = 1
@export_range (0, 99999) var bulletBounces: int = 0
@export_range (0.2, 3) var bulletRange: float = 3
@export_range (0, 100) var poison: float = 0
@export var explodingBullets = false
@export var selfDamage = true

#Fire Stats
@export_range (1, 99999) var bulletAmount: int = 4
@export_range (1, 99999) var bulletsShot: int = 1
@export_range (0, 99999) var bulletSpread: float = 0.1
@export_range (0.005, 99999) var attackSpeed: float = 0.4
@export_range (0.001, 99999) var timerSpeed := 0.2
@export var autoFire = false

#Reload
@export_range (0.01, 99999) var reloadTime: float = 3.0

#State
var currentBulletAmount := 0
var can_shoot := true
var reloading := false
var require_shoot_release := true
var _owner_peer_id: int = 1

#References
var Bullet = preload("res://Assets/Scenes/bullet.tscn")
@onready var cooldown: Timer = $coolDown
@onready var reload_timer: Timer = $Reload

func _ready() -> void:
	_owner_peer_id = _find_owner_peer_id()
	currentBulletAmount = bulletAmount
	require_shoot_release = Input.is_action_pressed("Shoot")
	await get_tree().process_frame
	cooldown.wait_time = attackSpeed
	cooldown.one_shot = true
	cooldown.timeout.connect(_on_cooldown_timeout)
	reload_timer.wait_time = reloadTime
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_timeout)
	$".."/Control/Reload.max_value = reloadTime
	$".."/Control/Reload.value = 0
	$".."/Control/Reload.hide()
	_update_bullet_text(bulletAmount)

func _update_bullet_text(amount: int) -> void:
	$"../../BulletAmount".text = str(amount)

func _physics_process(_delta: float) -> void:
	if multiplayer.get_unique_id() != _owner_peer_id:
		return

	if require_shoot_release:
		if Input.is_action_pressed("Shoot"):
			return
		require_shoot_release = false

	var should_shoot = false
	if autoFire:
		should_shoot = Input.is_action_pressed("Shoot") and can_shoot and not reloading and currentBulletAmount > 0
	else:
		should_shoot = Input.is_action_just_pressed("Shoot") and can_shoot and not reloading and currentBulletAmount > 0

	if should_shoot:
		var aim_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
		if aim_dir == Vector2.ZERO:
			aim_dir = Vector2.RIGHT
		var angles: Array = []
		for i in range(bulletsShot):
			var dir := aim_dir.normalized()
			if bulletSpread > 0.0:
				var half := bulletSpread * 0.5
				dir = dir.rotated(randf_range(-half, half)).normalized()
			angles.append(dir.angle())

		var stats = {
			"damage": damage,
			"speed": speed,
			"bulletSize": bulletSize,
			"bulletBounces": bulletBounces,
			"bulletRange": bulletRange,
			"poison": poison,
			"explodingBullets": explodingBullets,
			"selfDamage": selfDamage,
		}
		_fire_burst.rpc(angles, stats)

	if currentBulletAmount < 1 and not reloading:
		reloading = true
		can_shoot = false
		reload_timer.start()
		_sync_reload_ui.rpc(true, reloadTime)

	if reloading:
		var progress = reloadTime - reload_timer.time_left
		_sync_reload_progress.rpc(progress)

func _find_owner_peer_id() -> int:
	var n: Node = self
	while n != null:
		if n.is_in_group("Player"):
			return int(str(n.name))
		n = n.get_parent()
	return 1

@rpc("any_peer", "call_local")
func _fire_burst(angles: Array, stats: Dictionary) -> void:
	can_shoot = false
	currentBulletAmount -= bulletsShot
	if currentBulletAmount < 0:
		currentBulletAmount = 0
	_update_bullet_text(currentBulletAmount)
	_burst_shoot(angles, stats)

@rpc("any_peer", "call_local")
func _sync_reload_ui(show_bar: bool, max_val: float) -> void:
	var reload_bar = $".."/Control/Reload
	reload_bar.max_value = max_val
	reload_bar.value = 0
	if show_bar:
		reload_bar.show()
	else:
		reload_bar.hide()

@rpc("any_peer", "call_local")
func _sync_reload_progress(progress: float) -> void:
	$".."/Control/Reload.value = progress

func _on_cooldown_timeout() -> void:
	if not reloading:
		can_shoot = true

func _on_reload_timeout() -> void:
	currentBulletAmount = bulletAmount
	reloading = false
	can_shoot = true
	_update_bullet_text(currentBulletAmount)
	_sync_reload_ui.rpc(false, reloadTime)

func _burst_shoot(angles: Array, stats: Dictionary) -> void:
	if angles.size() > 1:
		for angle in angles:
			spawn_bullet_at_angle(angle, stats)
			await get_tree().create_timer(timerSpeed / max(1.0, (bulletsShot / 2.0))).timeout
	else:
		spawn_bullet_at_angle(angles[0], stats)
	cooldown.start()

func spawn_bullet_at_angle(angle: float, stats: Dictionary) -> void:
	var b = Bullet.instantiate()
	b.selfDamage = stats["selfDamage"]
	b.damage = stats["damage"]
	b.speed = stats["speed"]
	b.explodingBullets = stats["explodingBullets"]
	b.bulletBounces = stats["bulletBounces"]
	b.bulletRange = stats["bulletRange"]
	b.bulletSize = stats["bulletSize"]
	b.poison = stats["poison"]
	var shooter_node = get_parent().get_parent().get_parent()
	b.shooter = shooter_node
	get_tree().root.add_child(b)
	b.start(global_position, angle)
