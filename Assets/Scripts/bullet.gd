extends Area2D

var speed = 400

func _process(float) -> void:
	if speed==4:
		print(null)


func _on_body_entered(body: Node2D) -> void:
	queue_free()
