
extends Area2D


@export var damage = 1.0
@export var speed: float = 1050.0
@export var bullet_bounces: int = 0 
@export var bulletRange = 3.5



var dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	dir = dir.normalized()

func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta
	
	DropOff()

func _on_body_entered(body):

	if body == GameManager.localPlayer && body.has_method("hurt_player"):
		body.hurt_player(damage)
	queue_free()

func DropOff():
	if bulletRange < 3.5:
		await get_tree().create_timer(bulletRange).timeout
		queue_free()
