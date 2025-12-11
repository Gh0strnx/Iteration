extends Area2D

@export var speed = 720
@export var bulletBounces = 0

func _physics_process(delta):
	position += transform.x * speed * delta
	
	
	
func _on_body_entered(body: Node2D) -> void:
	queue_free()
