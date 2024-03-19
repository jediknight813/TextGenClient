extends Node2D
var auto_generate_response = true


func _ready():
	if Globals.hosting_game == true:
		$VBoxContainer/Row1/ImageStyle.text = Globals.image_style
	else: 
		self.hide()


func _on_check_box_toggled(toggled_on):
	auto_generate_response = toggled_on


func _on_image_style_text_changed(new_text):
	Globals.image_style = new_text
