extends CanvasLayer

var gun:
	get:
		return GameManager.localPlayer.get_node("Gun/Sprite2D/gun")

var player: CharacterBody2D:
	get:
		return GameManager.localPlayer

var rng = RandomNumberGenerator.new()
var CardsShown = 4

var common_count = 5
var uncommon_count = 2
var rare_count = 3
var epic_count = 1

var common_weight = 0.60 / common_count
var uncommon_weight = 0.25 / uncommon_count
var rare_weight = 0.11 / rare_count
var epic_weight = 0.04 / epic_count

var cards = [
	"Bounce",
	"Bandaid",
	"QuickReload",
	"Decay",
	"Medicine",
	"Refract",
	"Sniper",
	"Cannon",
	"GlassCannon",
	"Shrapnel",
	"BubbleWrap",
]

var weights = PackedFloat32Array([
	common_weight,   # Bounce
	common_weight,   # Bandaid
	common_weight,   # QuickReload
	common_weight,   # Decay
	common_weight,   # Medicine
	uncommon_weight, # Refract
	uncommon_weight, # Sniper
	rare_weight,     # Cannon
	rare_weight,     # GlassCannon
	rare_weight,     # Shrapnel
	epic_weight,     # BubbleWrap
])

var current_index = -1
var shown_cards = []
var is_loser = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if not is_loser:
		return
	if shown_cards.is_empty():
		return

	if Input.is_action_just_pressed("left"):
		current_index = (current_index - 1 + shown_cards.size()) % shown_cards.size()
		update_selection()
		sync_selection.rpc(current_index)

	if Input.is_action_just_pressed("right"):
		current_index = (current_index + 1) % shown_cards.size()
		update_selection()
		sync_selection.rpc(current_index)

	if Input.is_action_just_pressed("ui_accept"):
		apply_selected_card()

func callCard():
	for card in $Control/HBoxContainer.get_children():
		card.visible = false
		card.scale = Vector2(1.0, 1.0)

func show_cards(picked: Array):
	callCard()
	shown_cards = []
	for card_name in picked:
		var card = $Control/HBoxContainer.get_node_or_null(card_name)
		if card:
			card.visible = true
			card.pivot_offset = card.size / 2
			shown_cards.append(card)
		else:
			print("card not found: ", card_name)

	shown_cards.sort_custom(func(a, b): return a.get_index() < b.get_index())
	current_index = -1
	is_loser = multiplayer.get_unique_id() != GameManager.winningplayerid

func update_selection():
	for i in shown_cards.size():
		if i == current_index:
			shown_cards[i].scale = Vector2(1.2, 1.2)
		else:
			shown_cards[i].scale = Vector2(1.0, 1.0)

@rpc("any_peer", "call_local", "reliable")
func sync_selection(index: int):
	current_index = index
	update_selection()

func apply_selected_card():
	if shown_cards.is_empty():
		return
	var card_name = shown_cards[current_index].name
	print("picked: ", card_name)
	call(card_name)
	is_loser = false
	shown_cards.clear()
	hidden.rpc()

@rpc("any_peer", "call_local", "reliable")
func hidden():
	get_tree().paused = false
	self.hide()

func pick_cards() -> Array:
	var picked = []
	var temp_cards = cards.duplicate()
	var temp_weights = weights.duplicate()

	for i in CardsShown:
		var index = rng.rand_weighted(temp_weights)
		picked.append(temp_cards[index])
		temp_cards.remove_at(index)
		temp_weights.remove_at(index)

	print(picked)
	return picked

# COMMON
func Bounce():
	gun.bulletBounces += 1
	gun.speed -= gun.speed * 0.1

func QuickReload():
	gun.reloadTime -= gun.reloadTime * 0.25

func PocketMagazine():
	gun.bulletAmount += 3

func FastBall():
	gun.speed += gun.speed * 0.25
	gun.attackSpeed += gun.attackSpeed * 0.1

func Bandaid():
	player.health += player.max_health * 0.25

func Medicine():
	player.health += player.max_health * 0.1
	player.Regeneration += player.max_health * 0.1
	gun.attackSpeed += gun.attackSpeed * 0.1

func Electrolyte():
	gun.speed += gun.speed * 0.1
	player.speed += player.speed * 0.1

func Rage():
	gun.damage += gun.damage * 0.4
	player.speed += player.speed * 0.25
	player.blockCooldown += player.blockCooldown * 1.0

func Scatter():
	gun.bulletSpread += 0.08
	gun.bulletAmount += 1

func BatteryPack():
	player.speed += player.speed * 0.25
	gun.speed += gun.speed * 0.1

func Buckler():
	player.blockCooldown -= player.blockCooldown * 0.1

func Heavy():
	player.health += player.max_health * 0.25
	player.scale += Vector2(0.1, 0.1)

func Decay():
	gun.poison += 10

# UNCOMMON
func Refract():
	gun.bulletBounces += 2
	gun.speed += gun.speed * 0.1

func LifeSteal():
	player.LifeSteal += 10

func Buckshot():
	gun.bulletsShot += 2
	gun.reloadTime += gun.reloadTime * 0.1
	gun.damage += gun.damage * 0.25
	gun.bulletRange -= gun.bulletRange * 0.1

func Sniper():
	gun.bulletAmount = 1
	gun.damage += gun.damage * 1.0
	gun.bulletSpread -= gun.bulletSpread * 0.5

func Experience():
	gun.reloadTime -= gun.reloadTime * 0.25
	gun.attackSpeed -= gun.attackSpeed * 0.25

func Assassin():
	player.speed += player.speed * 0.4
	player.scale -= Vector2(0.1, 0.1)
	gun.damage -= gun.damage * 0.1
	player.health -= player.max_health * 0.1

func Medkit():
	player.health += player.max_health * 0.25
	player.Regeneration += player.max_health * 0.1

# RARE
func Cannon():
	gun.bulletSize += gun.bulletSize * 0.1
	gun.damage += gun.damage * 0.25
	gun.speed -= gun.speed * 0.25
	player.speed -= player.speed * 0.1

func Bound():
	gun.bulletRange -= gun.bulletRange * 0.5
	gun.reloadTime -= gun.reloadTime * 0.8
	gun.attackSpeed -= gun.attackSpeed * 0.8

func GlassCannon():
	player.health -= player.max_health * 0.7
	gun.damage += gun.damage * 1.25
	gun.reloadTime += gun.reloadTime * 0.25

func Shrapnel():
	gun.bulletAmount += 3
	gun.bulletsShot += 1
	gun.speed += gun.speed * 0.25
	gun.damage -= gun.damage * 0.4

# EPIC
func BubbleWrap():
	gun.selfDamage = false
	player.health += player.max_health * 0.1
	gun.bulletBounces += 3
	player.speed -= player.speed * 0.1

func MiniGun():
	gun.bulletAmount += 6
	gun.bulletsShot += 1
	gun.attackSpeed -= gun.attackSpeed * 0.25
	player.speed -= player.speed * 0.25

func Vampire():
	player.LifeSteal += 10
	gun.poison += 10
	gun.damage += gun.damage * 0.25

func Berserker():
	player.blockCooldown += 99999
	player.speed += player.speed * 0.25
	player.Regeneration -= player.Regeneration * 0.25
	gun.damage += gun.damage * 0.25
