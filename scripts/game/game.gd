extends Control

@onready var Message = $Message
@onready var gameNameText = $Text
@onready var http_request = $HTTPRequest
@onready var messages_container = $MessageContainer
@onready var background_image_http_request = $HTTPBackgroundRequest
@onready var host_options = $HostOptions
@onready var generate_background_button = $HostOptions/VBoxContainer/Row1/GenerateBackgroundButton
@onready var ImageBackground = $ImageBackground
@onready var send_message_button = $SendMessageButton
@onready var admin_generate_text = $HostOptions/VBoxContainer/Row2/GenerateAIResponseButton

var messages_list = []
var current_message_id = 0
var message_context_window_size = 20
var players_list = []
var current_image_base64_string = ""
var connected = false


# check if hosting game or joining game.
func _ready():
	start_game()


func start_game():
	multiplayer.multiplayer_peer.close()
	if Globals.hosting_game == true:
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(1027)
		get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
		multiplayer.multiplayer_peer = peer
		multiplayer.connect("peer_connected", _connected_to_server)
		gameNameText.text = "[center][b]"+Globals.username + "'s game"
		players_list.append({"username": Globals.username})
	else:
		var peer = ENetMultiplayerPeer.new()
		peer.create_client(Globals.join_ip, 1027)
		get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
		multiplayer.multiplayer_peer = peer
		
		
# get any players that just joined up to date.
func _connected_to_server(id):
	print("Player Joined: ", str(id))
	rpc("get_game_data", Globals.username, messages_list, id, current_message_id, players_list, current_image_base64_string)


@rpc("any_peer", "call_local")
func get_game_data(host_name, message_history, user_id, host_current_message_id, current_players_list, current_image_base64_string):	
	if user_id == multiplayer.get_unique_id():
		players_list = current_players_list
		current_message_id = host_current_message_id
		messages_container.set_messages(message_history)
		gameNameText.text = "[center][b]"+host_name + "'s game"
		rpc("send_chat_message", "Game", "[b]"+Globals.username+" has joined.", "Notification")
		rpc("add_new_player", Globals.username)
		
		if current_image_base64_string != "":
			rpc("set_background_image", current_image_base64_string)


# adds the new player to the hosts player list.
@rpc("any_peer", "call_local")
func add_new_player(username):
	if Globals.hosting_game == true:
		players_list.append({"username": username})
		rpc("update_player_list", players_list)


# updates all connected players list of players, should be changed in the future
@rpc("any_peer", "call_local")
func update_player_list(updated_player_list):
	if Globals.hosting_game == false:
		players_list = updated_player_list
	
	
func _on_send_message_button_pressed():
	rpc("send_chat_message", Globals.username, Message.text, "User")
	Message.text = ""


func _process(delta):
	if Input.is_action_just_released("enter"):
		rpc("send_chat_message", Globals.username, Message.text, "User")
		Message.text = ""
	
	if connected == false:
		var connection_status = multiplayer.multiplayer_peer.get_connection_status()
		# if disconnected go to multiplayer menu.
		if connection_status == 0:
			get_tree().change_scene_to_file("res://scenes/menus/multiplayer_menu.tscn")
		# if connected set to tree, to stop calling this every frame.
		if connection_status == 2:
			connected = true
			

@rpc("any_peer", "call_local")
func send_chat_message(username, message, role):
	if message == "":
		return
	
	messages_list.append({"username": username, "message": message, "id": current_message_id+1, "role": role})
	messages_container.add_message({"username": username, "message": message, "id": current_message_id+1})
	current_message_id += 1
	
	var ref_messages = get_latest_messages(message_context_window_size)
	# check if host, if host then call server to generate response.
	if Globals.hosting_game == true and role != "Narrator" and host_options.auto_generate_response == true and role != "Notification":
		rpc("disable_buttons", ["generate_text"])
		var json = JSON.stringify({"messages": ref_messages, "scenario": Globals.scenario, "players": players_list})
		var headers = ["Content-Type: application/json"]
		http_request.request("http://127.0.0.1:5000/generate_text", headers, HTTPClient.METHOD_POST, json)
		

# once the text has finished generating this gets called.
func _on_http_request_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	rpc("send_chat_message", "Narrator", json["response"], "Narrator")
	rpc("enable_buttons", ["generate_text", "generate_background"])


func get_latest_messages(limit):
	if len(messages_list) < limit:
		return messages_list
	
	var final_list = []
	messages_list.reverse()
	
	for message in messages_list:
		if limit >= 0 and message["role"] != "Notification":
			final_list.append(message)
			limit -= 1
	
	messages_list.reverse()
	final_list.reverse()
	return final_list


# generate a background for the current scene.
func _on_generate_background_button_pressed():
	# disable the button.
	generate_background_button.disabled = true
	rpc("disable_buttons", ["generate_text", "generate_background"])
	rpc("image_generation_state", true)
	var headers = ["Content-Type: application/json"]
	var ref_messages = get_latest_messages(3)
	var json = JSON.stringify({"messages": ref_messages, "scenario": Globals.scenario, "style": Globals.image_style})
	background_image_http_request.request("http://127.0.0.1:5000/generate_background_image", headers, HTTPClient.METHOD_POST, json)


func _on_http_background_request_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	current_image_base64_string = json["response"]
	rpc("set_background_image", json["response"])
	generate_background_button.disabled = false
	rpc("enable_buttons", ["generate_text", "generate_background"])
	rpc("image_generation_state", false)


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
	
# generate ai response to user messages.
func _on_generate_ai_response_button_pressed():
	rpc("disable_buttons", ["generate_text", "generate_background"])
	var ref_messages = get_latest_messages(message_context_window_size)
	var json = JSON.stringify({"messages": ref_messages, "scenario": Globals.scenario, "players": players_list})
	var headers = ["Content-Type: application/json"]
	http_request.request("http://127.0.0.1:5000/generate_text", headers, HTTPClient.METHOD_POST, json)


# sets the context window size.
func _on_spin_box_value_changed(value):
	message_context_window_size = value


# handle players quitting game.
func _on_quit_message_button_pressed():
	if Globals.hosting_game == true:
		for connected_peer in multiplayer.get_peers():
			rpc("quit_game", connected_peer)
		rpc("quit_game", multiplayer.multiplayer_peer.get_unique_id())
	else:
		rpc("quit_game", multiplayer.multiplayer_peer.get_unique_id())
	

@rpc("any_peer", "call_local")
func quit_game(peer_id):
	if multiplayer.multiplayer_peer.get_unique_id() == peer_id:
		get_tree().change_scene_to_file("res://scenes/menus/multiplayer_menu.tscn")
		

func _on_restart_story_button_pressed():
	while len(messages_list) >= 1:
		for message_item in messages_list:
			rpc("remove_message", message_item["id"])


@rpc("any_peer", "call_local")
func image_generation_state(is_image_generating):
	if is_image_generating:
		$BackgroundImage.hide()
		ImageBackground.get_children()[0].text = "Image Generating"
	else:
		$BackgroundImage.show()


# this is for disabling buttons on all clients.
@rpc("any_peer", "call_local")
func disable_buttons(button_list):
	if "generate_text" in button_list:
		send_message_button.disabled = true
		admin_generate_text.disabled = true
		
	if "generate_background" in button_list:
		generate_background_button.disabled = true


# this is for enabling buttons on all clients.
@rpc("any_peer", "call_local")
func enable_buttons(button_list):
	if "generate_text" in button_list:
		send_message_button.disabled = false
		admin_generate_text.disabled = false
	
	if "generate_background" in button_list:
		generate_background_button.disabled = false
	
	
