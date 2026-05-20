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
var winningplayerid = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if get_tree().get_nodes_in_group("alivePlayers").size() == 1 && ran == false:
		print("Game Finished" + str(get_tree().get_nodes_in_group("alivePlayers")))
		var winningplayerid = get_tree().get_nodes_in_group("alivePlayers")[0].id
		
		Players[winningplayerid].score += 1
		UpdatePlayerScore.rpc(Players)
		ran = true
		updateScores(winningplayerid)
		
		
		
	#print(Players)

@rpc("authority","call_remote") #runs on all clients
func UpdatePlayerScore(dict):
	print("i am ", multiplayer.get_unique_id(), " and i am updating my dictionary to ", Players)
	GameManager.Players = dict

func updateScores(id):
	var index = Players[id].index
	print("this has run for update scores with player id " + str(id) + "and index " + str(index) )
	match index:
		0:
			scoreBar1.value += 0.5
		1:
			scoreBar2.value += 0.5
		2:
			scoreBar3.value += 0.5
		3:
			scoreBar4.value += 0.5


	
