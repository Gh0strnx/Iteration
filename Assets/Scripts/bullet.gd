extends Area2D

var speed = 705

func _physics_process(delta):
	position += transform.x * speed * delta
	
	
func _on_body_entered(body: Node2D) -> void:
	queue_free()
