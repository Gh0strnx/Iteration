extends Node2D

@export var bulletAmount = 1
@export var reloadTime = 1
@export var attackSpeed = 0.5

var bulletPrefab = preload("res://Assets/Scenes/bullet.tscn")

var can_shoot: bool = true

func _ready() -> void:
	$Timer.wait_time = attackSpeed
	$Timer.one_shot = true
	$Timer.connect("timeout", Callable(self, "_on_timer_timeout"))

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("Shoot") and can_shoot:
		spawn_bullet()
		can_shoot = false
		$Timer.start()


func _on_timer_timeout() -> void:
	can_shoot = true
	
	

func spawn_bullet():
	
	var bullet = bulletPrefab.instantiate()
	bullet.position = global_position
	bullet.rotation = rotation
	bullet.look_at(get_global_mouse_position())
	get_tree().root.add_child(bullet)
	
