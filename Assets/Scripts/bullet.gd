
extends Area2D


@export var damage = 1.0
@export var speed: float = 720.0
@export var bullet_bounces: int = 0 
@export var bulletRange = 100



var dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	dir = dir.normalized()

func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta

func _on_body_entered(body):

	if body == GameManager.localPlayer && body.has_method("hurt_player"):
		body.hurt_player(damage)
	queue_free()
