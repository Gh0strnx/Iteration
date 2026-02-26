extends CharacterBody2D

##Can the player damage themselves - IMPLEMENTED
var selfDamage = true
##How much damage does a bullet do - IMPLEMENTED
var damage = 1.0
##How fast is a bullet - IMPLEMENTED
var speed: float = 10.5
##How many times can the bullet bounce - IMPLEMENTED
var bulletBounces: int = 0
##How far does the bullet go before stopping - NOT IMPLEMENTED
var bulletRange = 3.5
##How much damage over time (poison) does the bullet do - NOT IMPLEMENTED
var poison = 0
##Bullet sizer increaser
var bulletSize = 1

var dir: float = 0.0

func start(_position: Vector2, _direction: float) -> void:
	position = _position
	dir = _direction
	velocity = Vector2.RIGHT.rotated(dir) * (speed * 100)
	self.scale.y = bulletSize
	self.scale.x = bulletSize


func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.get_collider().has_method("hurt_player") && GameManager.localPlayer.blocking == false:
			if collision.get_collider().name == GameManager.localPlayer.name:
				if selfDamage == true:
					collision.get_collider().hurt_player(damage)
					queue_free()
			else:
				collision.get_collider().hurt_player(damage)
				queue_free()
				
		if bulletBounces != -1:
				velocity = velocity.bounce(collision.get_normal())
				bulletBounces = bulletBounces-1
				
		if bulletBounces == -1:
			queue_free()
		
			
	DropOff()


#func _on_body_entered(body):
#
	#if body == GameManager.localPlayer && body.has_method("hurt_player"):
		#body.hurt_player(damage)
	#queue_free()

func DropOff():
	if bulletRange < 3.5:
		await get_tree().create_timer(bulletRange).timeout
		queue_free()
