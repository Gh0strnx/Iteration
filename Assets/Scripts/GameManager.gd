extends Node
var Players = {}
var playerNodes = {}
var ran = false
var localPlayer : CharacterBody2D
var port
var ip
var lobbyCode
var choice = null
@onready var scoreBar1 = null
@onready var scoreBar2 = null
@onready var scoreBar3 = null
@onready var scoreBar4 = null
@onready var scoreBig1 = null
@onready var scoreBig2 = null
@onready var scoreBig3 = null
@onready var scoreBig4 = null
@onready var bigWin = null
var winningplayerid = null
var mapSelected = null
var maps = null
var prevchoice = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if bigWin:
		bigWin.visible = false

func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	if get_tree().get_nodes_in_group("alivePlayers").size() == 1 && ran == false:
		ran = true
		winningplayerid = get_tree().get_nodes_in_group("alivePlayers")[0].id
		Players[winningplayerid].roundPoints += 0.5
		Players[winningplayerid].score += 0.5
		UpdatePlayerScore.rpc(Players)
		updateScores(winningplayerid)
		RpcUpdateScores.rpc(winningplayerid)
		for pid in Players:
			UpdateColours(pid)
			RpcUpdateColours.rpc(pid)
		handleRoundEnd()

func handleRoundEnd():
	ShowBigWin.rpc()
	await get_tree().create_timer(3.0).timeout
	HideBigWin.rpc()
	if Players[winningplayerid].roundPoints == 1.0:
		Players[winningplayerid].roundPoints = 0
		for pid in Players:
			Players[pid].roundPoints = 0
		UpdatePlayerScore.rpc(Players)
		FullPointWin()
	elif Players[winningplayerid].roundPoints == 0.5:
		HalfPointWin()
	else:
		pass

@rpc("authority", "call_local")
func ShowBigWin():
	bigWin.show()

@rpc("authority", "call_local")
func HideBigWin():
	bigWin.hide()

@rpc("authority", "call_remote")
func UpdatePlayerScore(dict):
	print("i am ", multiplayer.get_unique_id(), " and i am updating my dictionary to ", dict)
	GameManager.Players = dict

func updateScores(id):
	var index = Players[id].index
	print("this has run for update scores with player id " + str(id) + " and index " + str(index))
	match index:
		0:
			scoreBar1.value += 0.5
			scoreBar1.tint_progress = GameManager.Players[id].hex
			scoreBig1.value += 0.5
		1:
			scoreBar2.value += 0.5
			scoreBar2.tint_progress = GameManager.Players[id].hex
			scoreBig2.value += 0.5
		2:
			scoreBar3.value += 0.5
			scoreBar3.tint_progress = GameManager.Players[id].hex
			scoreBig3.value += 0.5
		3:
			scoreBar4.value += 0.5
			scoreBar4.tint_progress = GameManager.Players[id].hex
			scoreBig4.value += 0.5

@rpc("authority", "call_remote")
func RpcUpdateScores(id):
	updateScores(id)

func UpdateColours(id):
	var index = Players[id].index
	print("this has run for UpdateColours with player id " + str(id) + " and index " + str(index))
	match index:
		0:
			scoreBig1.modulate = GameManager.Players[id].hex
		1:
			scoreBig2.modulate = GameManager.Players[id].hex
		2:
			scoreBig3.modulate = GameManager.Players[id].hex
		3:
			scoreBig4.modulate = GameManager.Players[id].hex

@rpc("authority", "call_remote")
func RpcUpdateColours(id):
	UpdateColours(id)

func HalfPointWin():
	print("this is a half point win")
	Map()
	print(get_tree().get_nodes_in_group("alivePlayers").size())

func FullPointWin():
	Map()
	RemoveScores.rpc()
	print("this is a full point win")
	var picked = get_tree().get_first_node_in_group("CardManager").pick_cards()
	ShowCards.rpc(picked)

@rpc("authority", "call_local")
func RemoveScores():
	for pid in Players:
		var index = Players[pid].index
		match index:
			0:
				scoreBar1.value = floor(scoreBar1.value)
				scoreBig1.value = 0
			1:
				scoreBar2.value = floor(scoreBar2.value)
				scoreBig2.value = 0
			2:
				scoreBar3.value = floor(scoreBar3.value)
				scoreBig3.value = 0
			3:
				scoreBar4.value = floor(scoreBar4.value)
				scoreBig4.value = 0
				
		Players[pid].roundPoints = 0
		Players[pid].score = floor(Players[pid].score)

@rpc("authority", "call_local", "reliable")
func ShowCards(picked: Array):
	var card_manager = get_tree().get_first_node_in_group("CardManager")
	card_manager.show()
	card_manager.show_cards(picked)

@rpc("authority", "call_local", "reliable")
func HideCards():
	get_tree().get_first_node_in_group("CardManager").hide()

func Map():
	if not multiplayer.is_server():
		return
	print(maps)
	print("this actually happened")
	var index = randi() % maps.size()
	if maps[index] == prevchoice:
		index = (index + 1) % maps.size()
	choice = maps[index]
	mapSelected = choice
	prevchoice = choice
	print(mapSelected)
	$/root/Node2D.rpc("applyMap", index)
	$/root/Node2D.applyMap(index)
