extends Node2D

##How many bullets does the player have - IMPLEMENTED
@export var bulletAmount := 3
##How long does it take for player to reload - IMPLEMENTED
@export var reloadTime := 3.0
##How fast can the player shoot - IMPLEMENTED
@export var attackSpeed := 0.4
##How innaccurate are the bullets - IMPLEMENTED
@export var bulletSpread := 0.05
##How many bullets get shot from one click - IMPLEMENTED
@export var bulletsShot := 1
#How big of a gap is there between the bullets from bulletsShot - IMPLEMENTED
@export var timerSpeed := 0.2
var Bullet = preload("res://assets/Scenes/bullet.tscn")

var bulletPrefab := preload("res://Assets/Scenes/bullet.tscn")
var currentBulletAmount := 0

var can_shoot := true
var reloading := false

var _owner_peer_id: int = 1
var require_shoot_release := true



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

func _physics_process(_delta: float) -> void:
	
	if multiplayer.get_unique_id() != _owner_peer_id:
		return
		
	if require_shoot_release:
		if Input.is_action_pressed("Shoot"):
			return
		require_shoot_release = false

	if Input.is_action_just_pressed("Shoot") and can_shoot and not reloading and currentBulletAmount > 0:
		var aim_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
		if aim_dir == Vector2.ZERO:
			aim_dir = Vector2.RIGHT
		_fire_burst.rpc(aim_dir)

	if currentBulletAmount < 1 and not reloading:
		reloading = true
		can_shoot = false
		reload_timer.start()

func _find_owner_peer_id() -> int:
	var n: Node = self
	while n != null:
		if n.is_in_group("Player"):
			return int(str(n.name))
		n = n.get_parent()
	return 1

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
	if bulletSpread > 0.0:
		var half := bulletSpread * 0.5
		dir = dir.rotated(randf_range(-half, half)).normalized()
	spawn_bullet(dir)

func spawn_bullet(aim_dir: Vector2) -> void:
	var b = Bullet.instantiate()
	var angle := aim_dir.angle()
	b.start(global_position, angle)
	get_tree().root.add_child(b)
