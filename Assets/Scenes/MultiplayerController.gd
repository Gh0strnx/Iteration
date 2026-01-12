extends Control

@export var Address = '127.0.0.1'
@export var port = 8910
var peer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# called by server and client
func peer_connected(id):
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
		print("cannot host: " + error)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players!")
	SendPlayerInformation($NameInput.text, multiplayer.get_unique_id())
	
@rpc("any_peer", "call_local")
func StartGame():
	var scene = load("res://Assets/Scenes/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()


func _on_join_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)


func _on_start_game_button_down() -> void:
	StartGame.rpc()
	
