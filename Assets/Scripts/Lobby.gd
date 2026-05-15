extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"../Lobby".show()
	$"../Score tracker".hide()
	$"../Map".hide()
	await get_tree().process_frame
	for player in get_tree().get_nodes_in_group("alivePlayers"):
		player.hide()
	
	get_tree().paused = true
	
	Done()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func Done():
	$"../Lobby".hide()
	$"../Score tracker".show()
	$"../Map".show()
	for player in get_tree().get_nodes_in_group("alivePlayers"):
		player.show()
	get_tree().paused = false
	
	
	
