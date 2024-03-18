extends Control


func _on_multiplayer_button_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/multiplayer_menu.tscn")


func _on_quit_game_button_pressed():
	get_tree().quit()
