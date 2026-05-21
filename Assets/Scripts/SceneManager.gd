extends Node2D
@export var PlayerScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.scoreBar1 = $"/root/Node2D/Score tracker/VBoxContainer/Player1Score"
	GameManager.scoreBar2 = $"/root/Node2D/Score tracker/VBoxContainer/Player2Score"
	GameManager.scoreBar3 = $"/root/Node2D/Score tracker/VBoxContainer/Player3Score"
	GameManager.scoreBar4 = $"/root/Node2D/Score tracker/VBoxContainer/Player4Score"
	
	GameManager.scoreBig1 = $"/root/Node2D/Score tracker/BigWin/HBoxContainer/Player1Score"
	GameManager.scoreBig2 = $"/root/Node2D/Score tracker/BigWin/HBoxContainer/Player2Score"
	GameManager.scoreBig3 = $"/root/Node2D/Score tracker/BigWin/HBoxContainer/Player3Score"
	GameManager.scoreBig4 = $"/root/Node2D/Score tracker/BigWin/HBoxContainer/Player4Score"
	GameManager.bigWin = $"/root/Node2D/Score tracker/BigWin"
	
	GameManager.scoreBar1.hide()
	GameManager.scoreBar2.hide()
	GameManager.scoreBar3.hide()
	GameManager.scoreBar4.hide()
	GameManager.scoreBig1.hide()
	GameManager.scoreBig2.hide()
	GameManager.scoreBig3.hide()
	GameManager.scoreBig4.hide()
	$"Score tracker/BigWin".hide()
	
	
	
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
		GameManager.scoreBig1.show()
	if alive_players_size >= 2:
		GameManager.scoreBar2.show()
		GameManager.scoreBig2.show()
	if alive_players_size >= 3:
		GameManager.scoreBar3.show()
		GameManager.scoreBig3.show()
	if alive_players_size >= 4:
		GameManager.scoreBar4.show()
		GameManager.scoreBig4.show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
