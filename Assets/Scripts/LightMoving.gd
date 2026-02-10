extends PointLight2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	await get_tree().process_frame
	
	
		
	if GameManager.localPlayer == get_parent():
		show()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
