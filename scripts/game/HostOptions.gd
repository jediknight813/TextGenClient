extends Node2D
var auto_generate_response = true


func _ready():
	if Globals.hosting_game == true:
		pass
	else: 
		self.hide()


func _on_check_box_toggled(toggled_on):
	auto_generate_response = toggled_on
