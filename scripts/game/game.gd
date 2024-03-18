extends Control

@onready var Message = $Message
@onready var gameNameText = $Text
@onready var http_request = $HTTPRequest
@onready var messages_container = $MessageContainer
@onready var background_image_http_request = $HTTPBackgroundRequest
@onready var host_options = $HostOptions

var messages_list = []

# check if hosting game or joining game.
func _ready():
	if Globals.hosting_game == true:
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(1027)
		get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
		multiplayer.multiplayer_peer = peer
		multiplayer.connect("peer_connected", _connected_to_server)
		gameNameText.text = Globals.username + "'s game"
	else:
		var peer = ENetMultiplayerPeer.new()
		peer.create_client(Globals.join_ip, 1027)
		get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
		multiplayer.multiplayer_peer = peer


# get any players that just joined up to date.
func _connected_to_server(id):
	print("Player Joined: ", str(id))
	rpc("get_game_data", Globals.username, messages_list, id)


@rpc("any_peer", "call_local")
func get_game_data(host_name, message_history, user_id):
	if user_id == multiplayer.get_unique_id():
		messages_container.set_messages(message_history)
		gameNameText.text = host_name + "'s game"


func _on_send_message_button_pressed():
	rpc("send_chat_message", Globals.username, Message.text)
	Message.text = ""


func _process(delta):
	if Input.is_action_just_released("enter"):
		rpc("send_chat_message", Globals.username, Message.text)
		Message.text = ""


@rpc("any_peer", "call_local")
func send_chat_message(username, message):
	messages_list.append({"username": username, "message": message, "id": len(messages_list)})
	messages_container.add_message({"username": username, "message": message})
	
	# check if host, if host then call server to generate response.
	if Globals.hosting_game == true and username != "Dungeon Master" and host_options.auto_generate_response == true:
		var json = JSON.stringify({"messages": messages_list, "scenario": Globals.scenario})
		var headers = ["Content-Type: application/json"]
		http_request.request("http://127.0.0.1:5000/generate_text", headers, HTTPClient.METHOD_POST, json)
		

# once the text has finished generating this gets called.
func _on_http_request_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	#print(json["response"])
	rpc("send_chat_message", "Dungeon Master", json["response"])


func get_latest_messages(limit):
	if len(messages_list) < limit:
		return messages_list
	
	var final_list = []
	messages_list.reverse()
	
	for message in messages_list:
		if limit >= 0:
			final_list.append(message)
			limit -= 1
	
	messages_list.reverse()
	final_list.reverse()
	return final_list
	
# generate a background for the current scene.
func _on_generate_background_button_pressed():
	var headers = ["Content-Type: application/json"]
	var ref_messages = get_latest_messages(3)
	var json = JSON.stringify({"messages": ref_messages, "scenario": Globals.scenario, "style": "Pen and paper sketch"})
	background_image_http_request.request("http://127.0.0.1:5000/generate_background_image", headers, HTTPClient.METHOD_POST, json)


func _on_http_background_request_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	rpc("set_background_image", json["response"])


# set the background image on all connected clients.
@rpc("any_peer", "call_local")
func set_background_image(base64_image):
	var bytes = Marshalls.base64_to_raw(base64_image);
	var image = Image.new() 
	image.load_png_from_buffer(bytes) 
	var texture = ImageTexture.create_from_image(image) 
	$BackgroundImage.texture = texture


# removes message from all clients.
func _on_message_container_remove_message(id):
	rpc("remove_message", id)


@rpc("any_peer", "call_local")
func remove_message(message_id):
	messages_container.remove_message_from_container(message_id)
	var index = 0
	for message in messages_list:
		if message["id"] == message_id:
			messages_list.remove_at(index)
			break
		else:
			index += 1
	print(messages_list)
	

# generate ai response to user messages.
func _on_generate_ai_response_button_pressed():
	var json = JSON.stringify({"messages": messages_list, "scenario": Globals.scenario})
	var headers = ["Content-Type: application/json"]
	http_request.request("http://127.0.0.1:5000/generate_text", headers, HTTPClient.METHOD_POST, json)
