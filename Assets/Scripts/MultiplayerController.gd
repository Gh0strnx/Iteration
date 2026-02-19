extends Control


@export var port = 8910
var peer
var hosting = false
var allowStart = false

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
	SendPlayerInformation.rpc_id(1, $NameInput.text, multiplayer.get_unique_id())
	
#called by client
func connection_failed():
	print("Connection Failed")
	
@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name,
			"id": id,
			"score": 0
		}
		
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i )

func _on_host_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 4)
	if error != OK:
		print("cannot host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	hosting = true
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players!")
	SendPlayerInformation($NameInput.text, multiplayer.get_unique_id())
	
@rpc("any_peer", "call_local")
func StartGame():
	if allowStart:
		var scene = load("res://Assets/Scenes/main.tscn").instantiate()
		get_tree().root.add_child(scene)
		self.hide()


func _on_join_button_down() -> void:
	if $NameInput2.text == "":
		GameManager.ip = '127.0.0.1' ##THIS ISNT LEGIT ONLY FOR DEBUGGING
		print(GameManager.ip)
	await get_tree().process_frame
	if !hosting:
		peer = ENetMultiplayerPeer.new()
		peer.create_client(GameManager.ip, port)
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)


func _on_start_game_button_down() -> void:
	StartGame.rpc()
	


func _on_address_input_text_changed(_new_text: String) -> void:
	GameManager.lobbyCode = $NameInput2.text
	
