extends Control

@onready var DirectConnectPopupContainer = $DirectConnectCenterContainer
@onready var HostGamePopupContainer = $HostGameCenterContainer


func _ready():
	DirectConnectPopupContainer.hide()
	HostGamePopupContainer.hide()


func _on_direct_connect_pressed():
	DirectConnectPopupContainer.show()
	HostGamePopupContainer.hide()
	
func _on_close_popup_pressed():
	DirectConnectPopupContainer.hide()
	HostGamePopupContainer.hide()


func _on_join_game_pressed():
	if $DirectConnectCenterContainer/DirectConnectContainer/Username.text != "" and $DirectConnectCenterContainer/DirectConnectContainer/ipaddress.text != "":
		Globals.join_ip = $DirectConnectCenterContainer/DirectConnectContainer/ipaddress.text
		Globals.username = $DirectConnectCenterContainer/DirectConnectContainer/Username.text
		Globals.hosting_game = false
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	

func _on_host_game_pressed():
	if $HostGameCenterContainer/HostGameContainer/Username.text != "" and $HostGameCenterContainer/HostGameContainer/scenario.text != "":
		Globals.username = $HostGameCenterContainer/HostGameContainer/Username.text
		Globals.hosting_game = true
		Globals.scenario = $HostGameCenterContainer/HostGameContainer/scenario.text
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_host_game_button_pressed():
	DirectConnectPopupContainer.hide()
	HostGamePopupContainer.show()
