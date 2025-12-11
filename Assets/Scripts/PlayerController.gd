extends CharacterBody2D

@export var speed = 700  # speed in pixels/sec

func _physics_process(delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	
	if velocity:
		$Sprite.play("run")
		$Sprite2.play("run")
	else:
		$Sprite.play("idle")
		$Sprite2.play("idle")
		
	if Input.is_action_just_pressed("left"):
		$Sprite.flip_h = true
		$Sprite2.flip_h = true
	elif Input.is_action_just_pressed("right"):
		$Sprite.flip_h = false
		$Sprite2.flip_h = false
	

	move_and_slide()
