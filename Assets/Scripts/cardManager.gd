extends Node2D
@onready var gun = $"../Gun"
var player = GameManager.localPlayer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



##COMMON CARDS
func Bounce():
	gun.bulletBounces += 1
	gun.speed -= 1.05
	
func QuickReload():
	gun.reloadTime -= 0.75
	
func PocketMagazine():
	gun.bulletAmount += 3
	
func FastBall():
	gun.speed += 1.05
	gun.attackSpeed -= 0.1
	
func Bandaid():
	player.health += 1
	
func Electrolyte():
	gun.speed += 1.05
	player.speed += 0.7
	
func Rage():
	gun.damage += 0.25
	player.speed += 0.7
	player.blockCooldown += 1.2


##UNCOMMON CARDS
func Refract():
	gun.bulletBounces += 2
	gun.speed += 1.05
	
func Medkit():
	player.health += 2.5
	pass
	
	
##RARE CARDS
func Cannon():
	gun.bulletSize += 0.25
	gun.damage += 0.25
	gun.speed -= 2.625
	player.speed -= 0.7


##EPIC CARDS
func BubbleWrap():
	gun.selfDamage = false
	player.health += 1
	gun.bulletBounces += 3
	player.speed -= 0.7
	
