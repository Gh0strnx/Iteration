extends Node
var Players = {}
var ran = false
var localPlayer : CharacterBody2D
var port
var ip
var lobbyCode
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if bigWin:
		bigWin.visible = false

func _process(_delta: float) -> void:
	if get_tree().get_nodes_in_group("alivePlayers").size() == 1 && ran == false:
		print("Game Finished" + str(get_tree().get_nodes_in_group("alivePlayers")))
		winningplayerid = get_tree().get_nodes_in_group("alivePlayers")[0].id
		Players[winningplayerid].score += 0.5
		UpdatePlayerScore.rpc(Players)
		ran = true
		updateScores(winningplayerid)
		for pid in Players:
			UpdateColours(pid)
			RpcUpdateColours.rpc(pid)
		handleRoundEnd()

func handleRoundEnd():
	await showBigWin()
	if Players[winningplayerid].score >= 1.0:
		for pid in Players:
			Players[pid].score = floor(Players[pid].score)
		UpdatePlayerScore.rpc(Players)
		FullPointWin()
	else:
		HalfPointWin()

@rpc("authority", "call_remote")
func UpdatePlayerScore(dict):
	print("i am ", multiplayer.get_unique_id(), " and i am updating my dictionary to ", Players)
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

func showBigWin():
	bigWin.show()
	await get_tree().create_timer(3.0).timeout
	bigWin.hide()

func HalfPointWin():
	print("this is a half point win")
	pass # TODO

func FullPointWin():
	print("this is a full point win")
	pass # TODO
