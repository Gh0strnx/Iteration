extends Node2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func Bounce():
	$Gun.bulletBounces += 1
	$Gun.speed -= 1.05

func Refract():
	$Gun.bulletBounces += 2
	$Gun.speed += 1.05

func BubbleWrap():
	$Gun.selfDamage = false
	GameManager.localPlayer.health += 1
	$Gun.bulletBounces += 3
	GameManager.localPlayer.speed -= 0.7
	
	
func Bandaid():
	GameManager.localPlayer.health += 1
	
	
func Medkit():
	GameManager.localPlayer.health += 2.5
	pass
	
func Cannon():
	$Gun.bulletSize += 0.25
	$Gun.damage += 0.25
	$Gun.speed -= 2.625
	GameManager.localPlayer.speed -= 0.7
