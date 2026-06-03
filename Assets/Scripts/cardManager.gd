extends CanvasLayer

var gun:
	get:
		return GameManager.localPlayer.get_node("Gun/Sprite2D/gun")

var player: CharacterBody2D:
	get:
		return GameManager.localPlayer

var rng = RandomNumberGenerator.new()


var common_count = 12
var uncommon_count = 7
var rare_count = 5
var epic_count = 4

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
	"Cache",
	"Mosquito",
	"Charge",
	"Tether",
	"Buckshot",
	"Overclocked",
	"Buckler",
	"Grenade",
	"Fastball",   
	"Heavy",
	"Assassin",
	"Scatter",
	"Rage",
	"Minigun",  
	"Vampire",
	"Berserker", 
	"Medkit",
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
	common_weight,   # Cache
	uncommon_weight, # Mosquito
	common_weight,   # Charge
	rare_weight,     # Tether
	uncommon_weight, # Buckshot
	uncommon_weight, # Overclocked
	common_weight,   # Buckler
	rare_weight,     # Grenade
	common_weight,   # FastBall
	common_weight,   # Heavy
	uncommon_weight, # Assassin
	common_weight,   # Scatter
	common_weight,   # Rage
	epic_weight,     # MiniGun
	epic_weight,     # Vampire
	epic_weight,     # Berserker
	uncommon_weight, # Medkit
])

var current_index = -1
var shown_cards = []
var is_loser = false
var loser_queue = []
var current_picker_id = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if not is_loser:
		$Select.show()
		return
	
	$Select.hide()
	
	if shown_cards.is_empty():
		return

	if Input.is_action_just_pressed("left"):
		if current_index == -1:
			current_index = shown_cards.size() - 1
		else:
			current_index = (current_index - 1 + shown_cards.size()) % shown_cards.size()
		update_selection()
		sync_selection.rpc(current_index)

	if Input.is_action_just_pressed("right"):
		current_index = (current_index + 1) % shown_cards.size()
		update_selection()
		sync_selection.rpc(current_index)

	if Input.is_action_just_pressed("ui_accept"):
		if current_index == -1:
			return
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
	is_loser = multiplayer.get_unique_id() == current_picker_id

func update_selection():
	for i in shown_cards.size():
		if i == current_index:
			shown_cards[i].scale = Vector2(1.6, 1.6)
		else:
			shown_cards[i].scale = Vector2(1.0, 1.0)

@rpc("any_peer", "call_local", "reliable")
func sync_selection(index: int):
	current_index = index
	update_selection()

func apply_selected_card():
	if shown_cards.is_empty():
		return
	if current_index == -1:
		return
	var card_name = shown_cards[current_index].name
	print("picked: ", card_name)
	call(card_name)
	#Syncing the ui
	player.update_health_bar()
	player.get_node("Gun/BulletAmount").text = str(gun.bulletAmount)
	player.get_node("Control/Anchor/Block").max_value = player.blockCooldown
	player.get_node("Gun/Sprite2D/Control/Reload").max_value = gun.reloadTime
	is_loser = false
	shown_cards.clear()
	if multiplayer.is_server():
		next_picker()
	else:
		picker_done.rpc_id(1)

@rpc("any_peer", "reliable")
func picker_done():
	if not multiplayer.is_server():
		return
	next_picker()

func next_picker():
	if loser_queue.is_empty():
		all_done.rpc()
		return
	current_picker_id = loser_queue.pop_front()
	var picked = pick_cards()
	set_picker_and_show.rpc(current_picker_id, picked)

@rpc("authority", "call_local", "reliable")
func set_picker_and_show(picker_id: int, picked: Array):
	get_tree().paused = true
	current_picker_id = picker_id
	self.show()
	show_cards(picked)

@rpc("authority", "call_local", "reliable")
func all_done():
	get_tree().paused = false
	self.hide()

func start_picking():
	var losers = []
	for pid in GameManager.Players:
		if pid != GameManager.winningplayerid:
			losers.append(pid)
	losers.sort_custom(func(a, b):
		return GameManager.Players[a].index < GameManager.Players[b].index
	)
	loser_queue = losers
	next_picker()

func pick_cards() -> Array:
	var picked = []
	var temp_cards = cards.duplicate()
	var temp_weights = weights.duplicate()

	for i in GameManager.CardsShown:
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

func Cache():
	gun.bulletAmount += 3

func FastBall():
	gun.speed += gun.speed * 0.25
	gun.attackSpeed += gun.attackSpeed * 0.1
	gun.autoFire = true

func Bandaid():
	player.max_health += player.max_health * 0.25
	player.health = player.max_health

func Medicine():
	player.max_health += player.max_health * 0.1
	player.health = player.max_health
	player.Regeneration += player.max_health * 0.1
	gun.attackSpeed += gun.attackSpeed * 0.1

func Charge():
	player.speed += player.speed * 0.25
	gun.speed += gun.speed * 0.1

func Scatter():
	gun.bulletSpread += gun.bulletSpread * 0.25
	gun.bulletsShot += 2

func Rage():
	gun.damage += gun.damage * 0.4
	player.speed += player.speed * 0.25
	player.blockCooldown += player.blockCooldown * 1.0

func Heavy():
	player.max_health += player.max_health * 0.25
	player.health = player.max_health
	player.scale += Vector2(0.1, 0.1)

func Buckler():
	player.blockCooldown -= player.blockCooldown * 0.1

func Decay():
	gun.poison += 10

# UNCOMMON
func Refract():
	gun.bulletBounces += 2
	gun.speed += gun.speed * 0.1

func Mosquito():
	player.LifeSteal += 10

func Buckshot():
	gun.bulletsShot += 2
	gun.reloadTime += gun.reloadTime * 0.1
	gun.damage += gun.damage * 0.25
	gun.bulletRange -= gun.bulletRange * 0.1

func Sniper():
	gun.bulletAmount = 1
	gun.damage += gun.damage * 1.0
	gun.speed += gun.speed * 1.0
	gun.bulletSpread -= gun.bulletSpread * 0.5
	gun.reloadTime += gun.reloadTime * 0.25

func Overclocked():
	gun.reloadTime -= gun.reloadTime * 0.25
	gun.attackSpeed -= gun.attackSpeed * 0.25

func Assassin():
	player.speed += player.speed * 0.4
	player.scale -= Vector2(0.1, 0.1)
	gun.damage -= gun.damage * 0.1
	player.max_health -= player.max_health * 0.1
	player.health = player.max_health

func Medkit():
	player.max_health += player.max_health * 0.25
	player.health = player.max_health
	player.Regeneration += player.max_health * 0.1

# RARE
func Cannon():
	gun.bulletSize += gun.bulletSize * 0.1
	gun.damage += gun.damage * 0.25
	gun.speed -= gun.speed * 0.25
	player.speed -= player.speed * 0.1
	gun.autoFire = false

func Tether():
	gun.bulletRange -= gun.bulletRange * 0.2
	gun.reloadTime -= gun.reloadTime * 0.8
	gun.attackSpeed -= gun.attackSpeed * 0.8
	gun.autoFire = true

func GlassCannon():
	player.max_health -= player.max_health * 0.7
	player.health = player.max_health
	gun.damage += gun.damage * 1.25
	gun.reloadTime += gun.reloadTime * 0.25
	gun.autoFire = false

func Grenade():
	gun.explodingBullets = true
	gun.damage += gun.damage * 0.25
	gun.attackSpeed += gun.attackSpeed * 0.25
	player.max_health -= player.max_health * 0.1
	player.health = min(player.health, player.max_health)

func Shrapnel():
	gun.bulletAmount += 3
	gun.bulletsShot += 1
	gun.speed += gun.speed * 0.25
	gun.damage -= gun.damage * 0.4
	gun.bulletSpread += gun.bulletSpread * 0.1

# EPIC
func BubbleWrap():
	gun.selfDamage = false
	player.max_health += player.max_health * 0.1
	player.health = player.max_health
	gun.bulletBounces += 3
	player.speed -= player.speed * 0.1

func MiniGun():
	gun.bulletAmount += 6
	gun.bulletsShot += 1
	gun.attackSpeed -= gun.attackSpeed * 0.25
	player.speed -= player.speed * 0.25
	gun.autoFire = true

func Vampire():
	player.LifeSteal += 10
	gun.poison += 10
	gun.damage += gun.damage * 0.25
	player.Regeneration += player.Regeneration * 0.1

func Berserker():
	player.blockCooldown += 99999
	player.canBlockPerm = false
	player.speed += player.speed * 0.25
	player.Regeneration -= player.Regeneration * 0.25
	gun.damage += gun.damage * 0.25
