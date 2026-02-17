extends CharacterBody2D

##Can the player damage themselves - IMPLEMENTED
@export var selfDamage = false
##How much damage does a bullet do - IMPLEMENTED
@export var damage = 1.0
##How fast is a bullet - IMPLEMENTED
@export var speed: float = 10.5
##How many times can the bullet bounce - IMPLEMENTED
@export var bulletBounces: int = 0
##How far does the bullet go before stopping - NOT IMPLEMENTED
@export var bulletRange = 3.5
##How much damage over time (poison) does the bullet do - NOT IMPLEMENTED
@export var poison = 0
var dir: float = 0.0

func start(_position: Vector2, _direction: float) -> void:
	position = _position
	dir = _direction
	velocity = Vector2.RIGHT.rotated(dir) * (speed * 100)



func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		if bulletBounces != -1:
				velocity = velocity.bounce(collision.get_normal())
				bulletBounces = bulletBounces-1
				print("bullet bounces left: " + str(bulletBounces))
		if collision.get_collider().has_method("hurt_player"):
			if collision.get_collider().name == GameManager.localPlayer.name:
				if selfDamage == true:
					collision.get_collider().hurt_player(damage)
				else:
					pass
			else:
				collision.get_collider().hurt_player(damage)
		if bulletBounces == -1:
			queue_free()
			
	DropOff()


func _on_body_entered(body):

	if body == GameManager.localPlayer && body.has_method("hurt_player"):
		body.hurt_player(damage)
	queue_free()

func DropOff():
	if bulletRange < 3.5:
		await get_tree().create_timer(bulletRange).timeout
		queue_free()
