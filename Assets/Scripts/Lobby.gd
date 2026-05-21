extends CanvasLayer
var colours = {"RED": "ff103e", "ORANGE": "ff671a", "YELLOW": "f9c000", "GREEN": "58970a", "BLUE": "3597ff", "PURPLE": "9c2bf2", "WHITE": "fbe4e5", "BROWN": "7c5937", "PINK": "fe53ed"}
var colour_keys = []
var current_index = 0
var canChange = true
var id = null
var index = null
var countdown_timer = 0.0
var counting_down = false
var colorWarning = false
var alreadyClicked = false

func _ready() -> void:
	colour_keys = colours.keys()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	$"../../Control".hide()
	$"Control2/StartButton".disabled = true
	$"Control2/CountdownLabel".hide()
	$"Control2/WarningLabel".hide()
	
	$"Control2/HBoxContainer/1".hide()
	$"Control2/HBoxContainer/2".hide()
	$"Control2/HBoxContainer/3".hide()
	$"Control2/HBoxContainer/4".hide()
	
	$"Control2/HBoxContainer/1/READY".hide()
	$"Control2/HBoxContainer/2/READY".hide()
	$"Control2/HBoxContainer/3/READY".hide()
	$"Control2/HBoxContainer/4/READY".hide()
	
	$"../Lobby".show()
	$"../Score tracker".hide()
	$"../Map".hide()
	await get_tree().process_frame
	
	id = multiplayer.get_unique_id()
	index = GameManager.Players[id].index
	var name = GameManager.Players[id].name
	if name == null or name == "":
		name = "Player " + str(id)
	
	match index:
		0:
			$"Control2/HBoxContainer/1/NAME".text = "[center]%s[/center]" % name
		1:
			$"Control2/HBoxContainer/2/NAME".text = "[center]%s[/center]" % name
		2:
			$"Control2/HBoxContainer/3/NAME".text = "[center]%s[/center]" % name
		3:
			$"Control2/HBoxContainer/4/NAME".text = "[center]%s[/center]" % name
	
	var alive_players_size = get_tree().get_nodes_in_group("alivePlayers").size()
	for player in get_tree().get_nodes_in_group("alivePlayers"):
		player.hide()
	
	get_tree().paused = true
	
	PlayerChecker(alive_players_size)
	sync_name.rpc(id, name)
	
	GameManager.Players[id].colour = colour_keys[0]
	GameManager.Players[id].hex = colours[colour_keys[0]]

func PlayerChecker(alive_players_size):
	if alive_players_size >= 1:
		$"Control2/HBoxContainer/1".show()
	if alive_players_size >= 2:
		$"Control2/HBoxContainer/2".show()
	if alive_players_size >= 3:
		$"Control2/HBoxContainer/3".show()
	if alive_players_size >= 4:
		$"Control2/HBoxContainer/4".show()

func get_taken_colours() -> Array:
	var taken = []
	for player_id in GameManager.Players:
		if player_id == id:
			continue
		var player = GameManager.Players[player_id]
		if player.get("ready", false) and player.get("colour", "") != "":
			taken.append(player.colour)
	return taken

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("left") && canChange:
		$"Control2/WarningLabel".hide()
		current_index = (current_index - 1 + 9) % 9
		ColourChanger()
		sync_colour.rpc(id, current_index)
		
	if Input.is_action_just_pressed("right") && canChange:
		$"Control2/WarningLabel".hide()
		current_index = (current_index + 1) % 9
		ColourChanger()
		sync_colour.rpc(id, current_index)
		
	if Input.is_action_just_pressed("Ready") && canChange:
		var taken = get_taken_colours()
		if colour_keys[current_index] in taken:
			colorWarning = true
			$"Control2/WarningLabel".show()
		else:
			colorWarning = false
			$"Control2/WarningLabel".hide()
			readyUp()
			sync_ready.rpc(id, true)
		
	if Input.is_action_just_pressed("Unready") && !canChange:
		unready()
		sync_ready.rpc(id, false)
		if multiplayer.is_server():
			counting_down = false
			countdown_timer = 0.0
			cancel_countdown()
			cancel_countdown.rpc()
		else:
			request_cancel_countdown.rpc_id(1)

	if Input.is_action_just_pressed("ui_cancel") && !canChange:
		unready()
		sync_ready.rpc(id, false)
		if multiplayer.is_server():
			counting_down = false
			countdown_timer = 0.0
			cancel_countdown()
			cancel_countdown.rpc()
		else:
			request_cancel_countdown.rpc_id(1)

	if counting_down && multiplayer.is_server():
		countdown_timer -= delta
		var display = ceili(countdown_timer)
		sync_countdown_display(display)
		sync_countdown_display.rpc(display)
		if countdown_timer <= 0:
			counting_down = false
			trigger_done()
			trigger_done.rpc()

func Done():
	$"../Lobby".hide()
	$"../Score tracker".show()
	$"../Map".show()
	for player in get_tree().get_nodes_in_group("alivePlayers"):
		player.show()
		player.apply_player_colour()
	get_tree().paused = false

func ColourChanger():
	if not GameManager.Players.has(id):
		print("id not found in Players dict")
		return
	
	var colour_name = colour_keys[current_index]
	var hex = colours[colour_name]
	GameManager.Players[id].colour = colour_name
	GameManager.Players[id].hex = hex
	var colour = Color("#" + hex)
	
	match index:
		0:
			$"Control2/HBoxContainer/1/Face".modulate = colour
			$"Control2/HBoxContainer/1/COLOUR".text = "[center]%s[/center]" % colour_name
		1:
			$"Control2/HBoxContainer/2/Face".modulate = colour
			$"Control2/HBoxContainer/2/COLOUR".text = "[center]%s[/center]" % colour_name
		2:
			$"Control2/HBoxContainer/3/Face".modulate = colour
			$"Control2/HBoxContainer/3/COLOUR".text = "[center]%s[/center]" % colour_name
		3:
			$"Control2/HBoxContainer/4/Face".modulate = colour
			$"Control2/HBoxContainer/4/COLOUR".text = "[center]%s[/center]" % colour_name

@rpc("any_peer", "reliable")
func sync_colour(sender_id: int, colour_index: int):
	if not GameManager.Players.has(sender_id):
		return
	
	var colour_name = colour_keys[colour_index]
	var hex = colours[colour_name]
	GameManager.Players[sender_id].colour = colour_name
	GameManager.Players[sender_id].hex = hex
	
	var player_index = GameManager.Players[sender_id].index
	var colour = Color("#" + hex)
	
	match player_index:
		0:
			$"Control2/HBoxContainer/1/Face".modulate = colour
			$"Control2/HBoxContainer/1/COLOUR".text = "[center]%s[/center]" % colour_name
		1:
			$"Control2/HBoxContainer/2/Face".modulate = colour
			$"Control2/HBoxContainer/2/COLOUR".text = "[center]%s[/center]" % colour_name
		2:
			$"Control2/HBoxContainer/3/Face".modulate = colour
			$"Control2/HBoxContainer/3/COLOUR".text = "[center]%s[/center]" % colour_name
		3:
			$"Control2/HBoxContainer/4/Face".modulate = colour
			$"Control2/HBoxContainer/4/COLOUR".text = "[center]%s[/center]" % colour_name

@rpc("any_peer", "reliable")
func sync_name(sender_id: int, player_name: String):
	if not GameManager.Players.has(sender_id):
		return
	
	var player_index = GameManager.Players[sender_id].index
	match player_index:
		0:
			$"Control2/HBoxContainer/1/NAME".text = "[center]%s[/center]" % player_name
		1:
			$"Control2/HBoxContainer/2/NAME".text = "[center]%s[/center]" % player_name
		2:
			$"Control2/HBoxContainer/3/NAME".text = "[center]%s[/center]" % player_name
		3:
			$"Control2/HBoxContainer/4/NAME".text = "[center]%s[/center]" % player_name

func readyUp():
	canChange = false
	GameManager.Players[id].ready = true
	check_all_ready()
	sync_player_colour.rpc_id(1, id, GameManager.Players[id].colour, GameManager.Players[id].hex)
	
	match index:
		0:
			$"Control2/HBoxContainer/1/Icon".modulate = Color("#78ff74")
			$"Control2/HBoxContainer/1/READY".show()
			$"Control2/HBoxContainer/1/COLOUR".hide()
		1:
			$"Control2/HBoxContainer/2/Icon".modulate = Color("#78ff74")
			$"Control2/HBoxContainer/2/READY".show()
			$"Control2/HBoxContainer/2/COLOUR".hide()
		2:
			$"Control2/HBoxContainer/3/Icon".modulate = Color("#78ff74")
			$"Control2/HBoxContainer/3/READY".show()
			$"Control2/HBoxContainer/3/COLOUR".hide()
		3:
			$"Control2/HBoxContainer/4/Icon".modulate = Color("#78ff74")
			$"Control2/HBoxContainer/4/READY".show()
			$"Control2/HBoxContainer/4/COLOUR".hide()

func unready():
	canChange = true
	GameManager.Players[id].ready = false
	colorWarning = false
	$"Control2/WarningLabel".hide()
	check_all_ready()
	
	match index:
		0:
			$"Control2/HBoxContainer/1/Icon".modulate = Color.WHITE
			$"Control2/HBoxContainer/1/READY".hide()
			$"Control2/HBoxContainer/1/COLOUR".show()
		1:
			$"Control2/HBoxContainer/2/Icon".modulate = Color.WHITE
			$"Control2/HBoxContainer/2/READY".hide()
			$"Control2/HBoxContainer/2/COLOUR".show()
		2:
			$"Control2/HBoxContainer/3/Icon".modulate = Color.WHITE
			$"Control2/HBoxContainer/3/READY".hide()
			$"Control2/HBoxContainer/3/COLOUR".show()
		3:
			$"Control2/HBoxContainer/4/Icon".modulate = Color.WHITE
			$"Control2/HBoxContainer/4/READY".hide()
			$"Control2/HBoxContainer/4/COLOUR".show()

@rpc("any_peer", "reliable")
func sync_player_colour(player_id: int, colour: String, hex: String):
	if multiplayer.is_server():
		GameManager.Players[player_id].colour = colour
		GameManager.Players[player_id].hex = hex
		broadcast_player_colour.rpc(player_id, colour, hex)

@rpc("authority", "reliable")
func broadcast_player_colour(player_id: int, colour: String, hex: String):
	GameManager.Players[player_id].colour = colour
	GameManager.Players[player_id].hex = hex

@rpc("any_peer", "reliable")
func sync_ready(sender_id: int, is_ready: bool):
	if not GameManager.Players.has(sender_id):
		return
	
	GameManager.Players[sender_id].ready = is_ready
	check_all_ready()
	
	var player_index = GameManager.Players[sender_id].index
	match player_index:
		0:
			$"Control2/HBoxContainer/1/Icon".modulate = Color("#78ff74") if is_ready else Color.WHITE
			$"Control2/HBoxContainer/1/READY".visible = is_ready
			$"Control2/HBoxContainer/1/COLOUR".visible = !is_ready
		1:
			$"Control2/HBoxContainer/2/Icon".modulate = Color("#78ff74") if is_ready else Color.WHITE
			$"Control2/HBoxContainer/2/READY".visible = is_ready
			$"Control2/HBoxContainer/2/COLOUR".visible = !is_ready
		2:
			$"Control2/HBoxContainer/3/Icon".modulate = Color("#78ff74") if is_ready else Color.WHITE
			$"Control2/HBoxContainer/3/READY".visible = is_ready
			$"Control2/HBoxContainer/3/COLOUR".visible = !is_ready
		3:
			$"Control2/HBoxContainer/4/Icon".modulate = Color("#78ff74") if is_ready else Color.WHITE
			$"Control2/HBoxContainer/4/READY".visible = is_ready
			$"Control2/HBoxContainer/4/COLOUR".visible = !is_ready

func check_all_ready():
	var all_ready = true
	for player_id in GameManager.Players:
		if not GameManager.Players[player_id].get("ready", false):
			all_ready = false
			break
	
	$"Control2/StartButton".disabled = !all_ready or !multiplayer.is_server()

func _on_start_button_pressed():
	if !alreadyClicked: 
		start_countdown()
		start_countdown.rpc()
		alreadyClicked = true
	

@rpc("authority", "reliable")
func start_countdown():
	counting_down = true
	countdown_timer = 3.0
	$"Control2/CountdownLabel".show()
	$"Control2/CountdownLabel".text = "3"

@rpc("any_peer", "reliable")
func request_cancel_countdown():
	if multiplayer.is_server():
		counting_down = false
		countdown_timer = 0.0
		cancel_countdown()
		cancel_countdown.rpc()

@rpc("authority", "reliable")
func cancel_countdown():
	counting_down = false
	alreadyClicked = false
	countdown_timer = 0.0
	$"Control2/CountdownLabel".hide()

@rpc("authority", "unreliable")
func sync_countdown_display(number: int):
	$"Control2/CountdownLabel".show()
	$"Control2/CountdownLabel".text = str(number)

@rpc("authority", "reliable")
func trigger_done():
	$"Control2/CountdownLabel".hide()
	Done()
