
extends Area2D

@export var speed: float = 720.0
@export var bullet_bounces: int = 0 


var dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	dir = dir.normalized()

func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
