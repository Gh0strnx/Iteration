extends PointLight2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	await get_tree().process_frame
	show()

#Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if GameManager.localPlayer:
		position = GameManager.localPlayer.position
