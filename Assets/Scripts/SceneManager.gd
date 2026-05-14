extends Node2D
@export var PlayerScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.scoreBar1 = $"/root/Node2D/Score tracker/VBoxContainer/Player1Score"
	GameManager.scoreBar2 = $"/root/Node2D/Score tracker/VBoxContainer/Player2Score"
	GameManager.scoreBar3 = $"/root/Node2D/Score tracker/VBoxContainer/Player3Score"
	GameManager.scoreBar4 = $"/root/Node2D/Score tracker/VBoxContainer/Player4Score"
	GameManager.scoreBar1.hide()
	GameManager.scoreBar2.hide()
	GameManager.scoreBar3.hide()
	GameManager.scoreBar4.hide()
	
	
	
	var index = 0
	for i in GameManager.Players:
		var currentPlayer = PlayerScene.instantiate()
		currentPlayer.name = str(GameManager.Players[i].id)
		add_child(currentPlayer)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				currentPlayer.global_position = spawn.global_position
				
		GameManager.Players[i].index = index
		index += 1
		
	var alive_players_size = get_tree().get_nodes_in_group("alivePlayers").size()
	print(GameManager.scoreBar1.name)
	if alive_players_size >= 1:
		GameManager.scoreBar1.show()
	if alive_players_size >= 2:
		GameManager.scoreBar2.show()
	if alive_players_size >= 3:
		GameManager.scoreBar3.show()
	if alive_players_size >= 4:
		GameManager.scoreBar4.show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
