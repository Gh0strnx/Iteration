extends Node2D

@export var bulletAmount := 3
@export var reloadTime := 3.0
@export var attackSpeed := 0.4
@export var bulletSpread := 0.05
@export var bulletsShot := 1
@export var timerSpeed := 0.3


var bulletPrefab := preload("res://Assets/Scenes/bullet.tscn")
var currentBulletAmount := 0



var can_shoot: bool = true
var reloading: bool = false

func _ready() -> void:
	currentBulletAmount = bulletAmount

	$coolDown.wait_time = attackSpeed
	$coolDown.one_shot = true
	$coolDown.connect("timeout", Callable(self, "_on_timer_timeout"))

	$Reload.wait_time = reloadTime
	$Reload.one_shot = true
	$Reload.connect("timeout", Callable(self, "_on_reload_timeout"))

func _physics_process(_delta: float) -> void:
	# Fire once per click, not every frame while held
	if Input.is_action_just_pressed("Shoot") and can_shoot and not reloading and currentBulletAmount > 0:
		_fire_burst()

	if currentBulletAmount < 1 and not reloading:
		reloading = true
		can_shoot = false
		$Reload.start()

func _fire_burst() -> void:
	can_shoot = false        # Block new shots immediately
	currentBulletAmount -= bulletsShot

	# Clamp so it does not go negative
	if currentBulletAmount < 0:
		currentBulletAmount = 0

	_burst_shoot()

func _on_timer_timeout() -> void:
	if not reloading:
		can_shoot = true

func _on_reload_timeout() -> void:
	currentBulletAmount = bulletAmount
	reloading = false
	can_shoot = true

# Separate async function for the burst
func _burst_shoot() -> void:
	if bulletsShot > 1:
		for i in range(bulletsShot):
			spawn_bullet()
			await get_tree().create_timer(timerSpeed/(bulletsShot/2)).timeout
	else:
		spawn_bullet()
	$coolDown.start()

func spawn_bullet() -> void:
	var bullet = bulletPrefab.instantiate()
	bullet.global_position = global_position
	bullet.look_at(get_global_mouse_position())
	get_tree().root.get_node("Node2D").add_child(bullet)
