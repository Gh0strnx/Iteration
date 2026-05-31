extends CanvasLayer


@export var port = 8910
var peer
var hosting = false
var allowStart = false
var hostScreen = false
var titleScreen = true
var joinScreen = false

var mainscene = preload("res://Assets/Scenes/main.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.port = port
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Back"):
		_on_back_button_down()

# called by server and client
func peer_connected(id):
	allowStart = true
	print("Player Connected " + str(id))
	
# called by server and client
func peer_disconnected(id):
	print("Player Disconnected " + str(id))
	
	
#called by client
func connected_to_server():
	$"JoinScreen/VBoxContainer/START".text = "JOINED LOBBY"
	$"JoinScreen/VBoxContainer/START".disabled = true
	print("Connected")
	
	#name input (1, name, multiplayer...)
	SendPlayerInformation.rpc_id(1, $"SettingsScreen/Vbox/NAME".text.strip_edges(), multiplayer.get_unique_id())
	
#called by client
func connection_failed():
	print("Connection Failed")
	print("No Host Found")
	$JoinScreen/ERRORS.show()
	$JoinScreen/ERRORS.text = "NO HOST FOUND"
	
@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name,
			"id": id,
			"score": 0,
			"roundPoints": 0,
			"colour": "RED",
			"hex": "ff103e",
			"index": ""
		}
		
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i )
		
	



func _on_host_button_down() -> void:
	if !hosting:
		peer = ENetMultiplayerPeer.new()
		var error = peer.create_server(port, 4)
		if error != OK:
			print("cannot host: " + str(error))
			
			if str(error) == "20":
				$TitleScreen/AlreadyHosting.text = "CANNOT HOST: ALREADY HOSTING"
				$TitleScreen/AlreadyHosting.show()
			else:
				$TitleScreen/AlreadyHosting.text = "CANNOT HOST: ERROR" + str(error)
				$TitleScreen/AlreadyHosting.show()
				
			return
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		hosting = true
		
		multiplayer.set_multiplayer_peer(peer)
		print("Waiting for Players!")
		SendPlayerInformation($"SettingsScreen/Vbox/NAME".text.strip_edges(), multiplayer.get_unique_id())
		$HostScreen.show()
		$TitleScreen.hide()
		
	
@rpc("any_peer", "call_local")
func StartGame():
	if allowStart:
		var scene = mainscene.instantiate()
		get_tree().root.add_child(scene)
		
		
			


# In MultiplayerController (CanvasLayer script)
func join_with_ip(ip: String, join_port: int) -> void:
	if !hosting:
		peer = ENetMultiplayerPeer.new()
		var error = peer.create_client(ip, join_port)
		if error != OK:
			print("Failed to create client: ", error)
			print("Invalid Code")
			$JoinScreen/ERRORS.show()
			$JoinScreen/ERRORS.text = "INVALID CODE"
			return
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)

func _on_start_button_down() -> void:
	StartGame.rpc()
	


func _on_address_input_text_changed(_new_text: String) -> void:
	GameManager.lobbyCode = $JoinScreen/CODE.text
	print("woah the text is being changed")
	print(GameManager.lobbyCode)
	

func _on_play_button_down() -> void:
	$TitleScreen/StartUp.hide()
	$TitleScreen/Selection.show()
	


func _on_quit_button_down() -> void:
	if titleScreen == true:
		get_tree().quit()
		
	


func _on_settings_button_down() -> void:
	$SettingsScreen.show()
	$TitleScreen.hide()


func _on_back_button_down() -> void:
	$JoinScreen/ERRORS.hide()
	$TitleScreen.show()
	$TitleScreen/Selection.hide()
	$TitleScreen/StartUp.show()
	$HostScreen.hide()
	$JoinScreen.hide()
	$SettingsScreen.hide()
	$TitleScreen/AlreadyHosting.hide()
	
	if hosting:
		multiplayer.multiplayer_peer.close()
		hosting = false
	

func _on_firstjoin_button_down() -> void:
	$JoinScreen/ERRORS.hide()
	$JoinScreen.show()
	$TitleScreen.hide()


func _on_title_screen_or_quit(should_quit: bool):
	if multiplayer.is_server():
		# Send to all clients first, then handle locally
		for id in GameManager.Players:
			if id != multiplayer.get_unique_id():
				return_to_title.rpc_id(id)
		await get_tree().create_timer(0.3).timeout
	return_to_title_local()
	if should_quit:
		get_tree().quit()

@rpc("any_peer", "call_remote", "reliable")
func return_to_title():
	return_to_title_local()

func return_to_title_local():
	get_tree().paused = false
	var scene = get_tree().get_first_node_in_group("SceneManager")
	if scene:
		scene.queue_free()
	GameManager.Players = {}
	GameManager.playerNodes = {}
	GameManager.ran = false
	GameManager.localPlayer = null
	GameManager.winningplayerid = null
	GameManager.maps = null
	GameManager.mapSelected = null
	GameManager.prevchoice = null
	GameManager.choice = null
	GameManager.scoreBar1 = null
	GameManager.scoreBar2 = null
	GameManager.scoreBar3 = null
	GameManager.scoreBar4 = null
	GameManager.scoreBig1 = null
	GameManager.scoreBig2 = null
	GameManager.scoreBig3 = null
	GameManager.scoreBig4 = null
	GameManager.bigWin = null
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		hosting = false
		allowStart = false
	var gameover = get_tree().get_first_node_in_group("GameOver")
	if gameover:
		gameover.hide()
	self.show()
	$TitleScreen.show()
	$TitleScreen/StartUp.show()
	$TitleScreen/Selection.hide()
	$HostScreen.hide()
	$JoinScreen.hide()
	$SettingsScreen.hide()
