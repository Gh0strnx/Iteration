extends Node2D
@export var PlayerScene : PackedScene
var DebugOn = false

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

	get_tree().get_first_node_in_group("CardManager").hide()
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
	$"Score tracker/VBoxContainer/FPS".text = "FPS: " + str(Engine.get_frames_per_second())
	if Input.is_action_just_pressed("Debug"):
		if DebugOn == false:
			$"Score tracker/VBoxContainer/FPS".show()
			DebugOn == true
		if DebugOn == true:
			$"Score tracker/VBoxContainer/FPS".hide()
			DebugOn == false
		

@rpc("authority", "call_local", "reliable")
func applyMap(map_index: int):
	print("applyMap called with index: ", map_index)
	GameManager.mapSelected = GameManager.maps[map_index]
	mapSelector()
	resetPlayers()
	print("ApplyMap is actually happening")

func resetPlayers():
	for player in GameManager.playerNodes.values():
		if not is_instance_valid(player):
			continue
		if not GameManager.Players.has(player.id):
			continue
		var player_index = GameManager.Players[player.id].index
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(player_index):
				player.global_position = spawn.global_position
				player.syncedPosition = spawn.global_position
		# Reset player 
		player.health = player.max_health
		player.get_node("Control/VBoxContainer/ProgressBar").max_value = player.max_health
		player.get_node("Control/VBoxContainer/ProgressBar").value = player.max_health
		player.alive = true
		player.death_processed = false
		GameManager.Players[player.id].alive = true
		player.regen_timer = 0.0
		# Reset gun
		var gun = player.get_node("Gun/Sprite2D/gun")
		gun.currentBulletAmount = gun.bulletAmount
		gun.can_shoot = true
		gun.reloading = false
		gun.reload_timer.stop()
		gun.reload_timer.wait_time = gun.reloadTime
		gun.cooldown.stop()
		gun.cooldown.wait_time = gun.attackSpeed
		gun.require_shoot_release = false
		player.get_node("Gun/Sprite2D/Control/Reload").max_value = gun.reloadTime
		player.get_node("Gun/BulletAmount").text = str(gun.bulletAmount)
		player.get_node("Gun/Sprite2D/Control/Reload").hide()
		player.get_node("Gun/Sprite2D/Control/Reload").value = 0
		# Reset block 
		player.canBlock = true
		player.blocking = false
		player.block_cooldown_active = false
		player.block_cooldown_timer = 0.0
		player.get_node("Control/Anchor/Block").max_value = player.blockCooldown
		player.get_node("Control/Anchor/Block").value = player.blockCooldown
		player.get_node("Control/Anchor/Block").hide()
		# Bring back shadows for alive players
		for node in get_tree().get_nodes_in_group("global_canvas_modulate"):
			if GameManager.localPlayer.is_in_group("alivePlayers"):
				node.show()
		# Remove bullets
		for bullet in get_tree().get_nodes_in_group("bullet"):
			bullet.queue_free()
		# Remove explosions
		for explosions in get_tree().get_nodes_in_group("explosions"):
			explosions.queue_free()
		# Visibility and collision
		player.show()
		player.get_node("Collision").disabled = false
		if not player.is_in_group("alivePlayers"):
			player.add_to_group("alivePlayers")
	if multiplayer.is_server():
		if get_tree().get_nodes_in_group("alivePlayers").size() == 1:
			await get_tree().process_frame
			resetPlayers()
		else:
			GameManager.ran = false

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
	$Map/Map4.show()
	$Map/Map5.show()
	$Map/Map6.show()
	$Map/Map4/Ground.collision_enabled = true
	$Map/Map4/Walls.collision_enabled = true
	$Map/Map4/Roof.collision_enabled = true
	$Map/Map5/Ground.collision_enabled = true
	$Map/Map5/Walls.collision_enabled = true
	$Map/Map5/Roof.collision_enabled = true
	$Map/Map6/Ground.collision_enabled = true
	$Map/Map6/Walls.collision_enabled = true
	$Map/Map6/Roof.collision_enabled = true
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
	if GameManager.mapSelected != GameManager.maps[3]:
		$Map/Map4/Ground.collision_enabled = false
		$Map/Map4/Walls.collision_enabled = false
		$Map/Map4/Roof.collision_enabled = false
		$Map/Map4.hide()
		print("map4 not chosen")
	if GameManager.mapSelected != GameManager.maps[4]:
		$Map/Map5/Ground.collision_enabled = false
		$Map/Map5/Walls.collision_enabled = false
		$Map/Map5/Roof.collision_enabled = false
		$Map/Map5.hide()
		print("map5 not chosen")
	if GameManager.mapSelected != GameManager.maps[5]:
		$Map/Map6/Ground.collision_enabled = false
		$Map/Map6/Walls.collision_enabled = false
		$Map/Map6/Roof.collision_enabled = false
		$Map/Map6.hide()
		print("map6 not chosen")


func update_round_texture() -> void:
	var texture = load("res://Assets/Textures/MatchesWon/Matches" + str(GameManager.MaxScore) + ".png")
	$"Score tracker/VBoxContainer/Player1Score".texture_under = texture
	$"Score tracker/VBoxContainer/Player1Score".texture_progress = texture
	$"Score tracker/VBoxContainer/Player1Score".max_value = GameManager.MaxScore
	$"Score tracker/VBoxContainer/Player2Score".texture_under = texture
	$"Score tracker/VBoxContainer/Player2Score".texture_progress = texture
	$"Score tracker/VBoxContainer/Player2Score".max_value = GameManager.MaxScore
	$"Score tracker/VBoxContainer/Player3Score".texture_under = texture
	$"Score tracker/VBoxContainer/Player3Score".texture_progress = texture
	$"Score tracker/VBoxContainer/Player3Score".max_value = GameManager.MaxScore
	$"Score tracker/VBoxContainer/Player4Score".texture_under = texture
	$"Score tracker/VBoxContainer/Player4Score".texture_progress = texture
	$"Score tracker/VBoxContainer/Player4Score".max_value = GameManager.MaxScore
	
