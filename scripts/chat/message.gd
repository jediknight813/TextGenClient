extends Control

var id = 0

func set_id(id_number):
	id = id_number

func set_username(username):
	$VBoxContainer/UsernameText.text = "[b]"+username
	
func set_message(message):
	$VBoxContainer/MessageText.text = message

func _on_delete_message_mouse_entered():
	if Globals.hosting_game == true:
		$DeleteMessage/Button.show()

func _on_delete_message_mouse_exited():
	$DeleteMessage/Button.hide()

func _on_button_pressed():
	$"../../../".remove_message_multiplayer(id)
