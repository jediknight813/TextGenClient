extends Control

@onready var messages_container = $ScrollContainer/VBoxContainer
@onready var message_scene = preload("res://scenes/chat/message.tscn")
signal remove_message(id)


func set_messages(messages):
	for message in messages:
		var new_message = message_scene.instantiate()
		new_message.set_username(message["username"])
		new_message.set_message(message["message"])
		new_message.set_id(message["id"])
		messages_container.add_child(new_message)	


func add_message(message):
	var new_message = message_scene.instantiate()
	new_message.set_username(message["username"])
	new_message.set_message(message["message"])
	new_message.set_id(message["id"])
	messages_container.add_child(new_message)


func check_message_number():
	return messages_container.get_child_count()


func remove_message_multiplayer(id):
	emit_signal("remove_message", id)		 	


func remove_message_from_container(message_id):
	for message in messages_container.get_children():
		if message.id == message_id:
			message.queue_free()
