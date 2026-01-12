# gun.gd (attach to gun.tscn / your shooting node)
extends Node2D

@export var bulletAmount := 3
@export var reloadTime := 3.0
@export var attackSpeed := 0.4
@export var bulletSpread := 0.05
@export var bulletsShot := 1
@export var timerSpeed := 0.2

@export var projectile_parent_path: NodePath = NodePath("/root/Node2D") # change to your World/Projectiles node

var bulletPrefab := preload("res://Assets/Scenes/bullet.tscn")
var currentBulletAmount := 0

var can_shoot: bool = true
var reloading: bool = false

@onready var cooldown: Timer = $coolDown
@onready var reload_timer: Timer = $Reload

func _ready() -> void:
	currentBulletAmount = bulletAmount

	cooldown.wait_time = attackSpeed
	cooldown.one_shot = true
	cooldown.timeout.connect(_on_cooldown_timeout)

	reload_timer.wait_time = reloadTime
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_timeout)

func _physics_process(_delta: float) -> void:
	# Only the local player should read mouse + input.
	# If you have a proper authority setup, prefer:
	# if not is_multiplayer_authority(): return
	# If not, use your own local-player check here.

	if Input.is_action_just_pressed("Shoot") and can_shoot and not reloading and currentBulletAmount > 0:
		var aim_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
		if aim_dir == Vector2.ZERO:
			aim_dir = Vector2.RIGHT
		_fire_burst.rpc(aim_dir)

	if currentBulletAmount < 1 and not reloading:
		reloading = true
		can_shoot = false
		reload_timer.start()

@rpc("any_peer", "call_local")
func _fire_burst(aim_dir: Vector2) -> void:
	can_shoot = false
	currentBulletAmount -= bulletsShot
	if currentBulletAmount < 0:
		currentBulletAmount = 0

	_burst_shoot(aim_dir)

func _on_cooldown_timeout() -> void:
	if not reloading:
		can_shoot = true

func _on_reload_timeout() -> void:
	currentBulletAmount = bulletAmount
	reloading = false
	can_shoot = true

func _burst_shoot(aim_dir: Vector2) -> void:
	if bulletsShot > 1:
		for i in range(bulletsShot):
			_spawn_bullet_with_spread(aim_dir)
			await get_tree().create_timer(timerSpeed / max(1.0, (bulletsShot / 2.0))).timeout
	else:
		_spawn_bullet_with_spread(aim_dir)

	cooldown.start()

func _spawn_bullet_with_spread(base_dir: Vector2) -> void:
	var dir := base_dir.normalized()

	# Optional spread (radians). bulletSpread was already in your script.
	if bulletSpread > 0.0:
		var half := bulletSpread * 0.5
		dir = dir.rotated(randf_range(-half, half)).normalized()

	spawn_bullet(dir)

func spawn_bullet(aim_dir: Vector2) -> void:
	var bullet = bulletPrefab.instantiate()
	bullet.global_position = global_position
	bullet.dir = aim_dir.normalized()
	bullet.rotation = bullet.dir.angle() # visual only

	var parent: Node = get_node(projectile_parent_path)
	parent.add_child(bullet)
