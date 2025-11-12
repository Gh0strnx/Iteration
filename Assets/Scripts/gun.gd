extends Node2D

@export var bulletAmount = 3
@export var reloadTime = 3
@export var attackSpeed = 0.5

var bulletPrefab = preload("res://Assets/Scenes/bullet.tscn")
var currentBulletAmount = bulletAmount

var can_shoot: bool = true
var reloading: bool = false

func _ready() -> void:
	# Shot cooldown timer
	$coolDown.wait_time = attackSpeed
	$coolDown.one_shot = true
	$coolDown.connect("timeout", Callable(self, "_on_timer_timeout"))
	
	# Reload timer
	$Reload.wait_time = reloadTime
	$Reload.one_shot = true
	$Reload.connect("timeout", Callable(self, "_on_reload_timeout"))

func _physics_process(_delta: float) -> void:
	# Only shoot if not reloading, can shoot, and have bullets
	if Input.is_action_pressed("Shoot") and can_shoot and not reloading and currentBulletAmount > 0:
		currentBulletAmount -= 1
		spawn_bullet()
		can_shoot = false
		$coolDown.start()

	# Start reload once when empty
	if currentBulletAmount < 1 and not reloading:
		reloading = true
		can_shoot = false
		$Reload.start()

func _on_timer_timeout() -> void:
	# Cooldown finished. If not reloading, allow next shot
	if not reloading:
		can_shoot = true

func _on_reload_timeout() -> void:
	# Refill clip after reload
	currentBulletAmount = bulletAmount
	reloading = false
	can_shoot = true

func spawn_bullet():
	var bullet = bulletPrefab.instantiate()
	bullet.position = global_position
	bullet.look_at(get_global_mouse_position())
	get_tree().root.get_node("Node2D").add_child(bullet)
