extends Node2D
@export var PlayerScene : PackedScene

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

	GameManager.playerNodes = {}
	var index = 0
	for i in GameManager.Players:
		var currentPlayer = PlayerScene.instantiate()
		currentPlayer.name = str(GameManager.Players[i].id)
		add_child(currentPlayer)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				currentPlayer.global_position = spawn.global_position
		GameManager.Players[i].index = index
		GameManager.playerNodes[i] = currentPlayer
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

func _process(_delta: float) -> void:
	pass

@rpc("authority", "call_local", "reliable")
func applyMap(map_index: int):
	print("applyMap called with index: ", map_index)
	GameManager.mapSelected = GameManager.maps[map_index]
	mapSelector()
	resetPlayers()

func resetPlayers():
	GameManager.ran = false
	for player in GameManager.playerNodes.values():
		var player_index = GameManager.Players[player.id].index
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(player_index):
				player.global_position = spawn.global_position
				player.syncedPosition = spawn.global_position
		# Reset player stats
		player.health = player.max_health
		player.alive = true
		player.death_processed = false
		GameManager.Players[player.id].alive = true
		player.get_node("Control/VBoxContainer/ProgressBar").value = player.max_health
		# Reset block state
		player.canBlock = true
		player.blocking = false
		player.block_cooldown_active = false
		player.block_cooldown_timer = 0.0
		player.get_node("Control/Anchor/Block").hide()
		player.get_node("Control/Anchor/Block").value = player.blockCooldown
		player.regen_timer = 0.0
		# Reset gun
		var gun = player.get_node("Gun/Sprite2D/gun")
		gun.currentBulletAmount = gun.bulletAmount
		gun.can_shoot = true
		gun.reloading = false
		gun.reload_timer.stop()
		gun.cooldown.stop()
		gun.require_shoot_release = false
		player.get_node("Gun/Control/Reload").hide()
		player.get_node("Gun/Control/Reload").value = 0
		# Visibility and collision
		player.show()
		player.get_node("Collision").disabled = false
		if not player.is_in_group("alivePlayers"):
			player.add_to_group("alivePlayers")

func mapSelector():
	print("mapselector actually happened")
	$Map/Map1.show()
	$Map/Map2.show()
	$Map/Map3.show()
	$Map/Map1/Ground.collision_enabled = true
	$Map/Map1/Walls.collision_enabled = true
	$Map/Map1/Roof.collision_enabled = true
	$Map/Map2/Ground.collision_enabled = true
	$Map/Map2/Walls.collision_enabled = true
	$Map/Map2/Roof.collision_enabled = true
	$Map/Map3/Ground.collision_enabled = true
	$Map/Map3/Walls.collision_enabled = true
	$Map/Map3/Roof.collision_enabled = true
	if GameManager.mapSelected != GameManager.maps[0]:
		$Map/Map1/Ground.collision_enabled = false
		$Map/Map1/Walls.collision_enabled = false
		$Map/Map1/Roof.collision_enabled = false
		$Map/Map1.hide()
		print("map1 not chosen")
	if GameManager.mapSelected != GameManager.maps[1]:
		$Map/Map2/Ground.collision_enabled = false
		$Map/Map2/Walls.collision_enabled = false
		$Map/Map2/Roof.collision_enabled = false
		$Map/Map2.hide()
		print("map2 not chosen")
	if GameManager.mapSelected != GameManager.maps[2]:
		$Map/Map3/Ground.collision_enabled = false
		$Map/Map3/Walls.collision_enabled = false
		$Map/Map3/Roof.collision_enabled = false
		$Map/Map3.hide()
		print("map3 not chosen")
