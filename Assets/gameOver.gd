extends CanvasLayer

func _on_quit_button_down() -> void:
	get_tree().get_first_node_in_group("MultiplayerController")._on_title_screen_or_quit(true)

func _on_title_screen_button_down() -> void:
	get_tree().get_first_node_in_group("MultiplayerController")._on_title_screen_or_quit(false)
