extends CanvasLayer


@export var port = 8910
var peer
var hosting = false
var allowStart = false
var hostScreen = false
var titleScreen = true
var joinScreen = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Menu Stuff/NameInput2".hide()
	$"Menu Stuff/NameInput3".hide()
	$"Menu Stuff/HBoxContainer/StartGame".hide()
	$"Menu Stuff/HBoxContainer/StartGame".hide()
	GameManager.port = port
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# called by server and client
func peer_connected(id):
	allowStart = true
	print("Player Connected " + str(id))
	
# called by server and client
func peer_disconnected(id):
	print("Player Disconnected " + str(id))
	
	
#called by client
func connected_to_server():
	print("Connected")
	#name input (1, name, multiplayer...)
	SendPlayerInformation.rpc_id(1, $"Menu Stuff/NameInput".text, multiplayer.get_unique_id())
	
#called by client
func connection_failed():
	print("Connection Failed")
	
@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name,
			"id": id,
			"score": 0,
			"colour": "red",
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
			return
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		hosting = true
		
		multiplayer.set_multiplayer_peer(peer)
		print("Waiting for Players!")
		SendPlayerInformation($"Menu Stuff/NameInput".text, multiplayer.get_unique_id())
		$"Menu Stuff/NameInput3".show()
		$"Menu Stuff/HBoxContainer/StartGame".show()
		$"Menu Stuff/HBoxContainer/Join".hide()
		#$"Menu Stuff/HBoxContainer/Host".hide()
		hostScreen = true
		titleScreen = false
		joinScreen = false
		$"Menu Stuff/Back".text = " BACK "
	
@rpc("any_peer", "call_local")
func StartGame():
	if allowStart:
		var scene = load("res://Assets/Scenes/main.tscn").instantiate()
		get_tree().root.add_child(scene)
		$"Menu Stuff".hide()
		
			


func _on_join_button_down() -> void:
	if $"Menu Stuff/NameInput2".text == "":
		GameManager.ip = '127.0.0.1' ##THIS ISNT LEGIT ONLY FOR DEBUGGING
		print(GameManager.ip)
	await get_tree().process_frame	
	if joinScreen == false:
		$"Menu Stuff/HBoxContainer/StartGame".hide()
		$"Menu Stuff/HBoxContainer/Host".hide()
		#$"Menu Stuff/HBoxContainer/Join".hide()
		$"Menu Stuff/NameInput2".show()
		joinScreen = true
		titleScreen = false
		hostScreen = false
		$"Menu Stuff/Back".text = " BACK "
	elif !hosting:
		peer = ENetMultiplayerPeer.new()
		peer.create_client(GameManager.ip, port)
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)

func _on_start_game_button_down() -> void:
	StartGame.rpc()
	


func _on_address_input_text_changed(_new_text: String) -> void:
	GameManager.lobbyCode = $"Menu Stuff/NameInput2".text
	

func _on_play_button_down() -> void:
	$"Menu Stuff".show()
	$"TitleScreen".hide()


func _on_back_button_down() -> void:
	if titleScreen == true:
		get_tree().quit()
		
	
	if joinScreen == true:
		$"Menu Stuff/HBoxContainer/Host".show()
		$"Menu Stuff/NameInput2".hide()
		joinScreen = false
		
	if hostScreen == true:
		$"Menu Stuff/NameInput3".hide()
		$"Menu Stuff/HBoxContainer/StartGame".hide()
		$"Menu Stuff/HBoxContainer/Join".show()
		joinScreen = false
		multiplayer.multiplayer_peer.close()
		hosting = false
		
	titleScreen = true
	$"Menu Stuff/Back".text = " QUIT "
		
