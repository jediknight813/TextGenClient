extends Node3D


var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene


func _on_host_pressed():
	peer.create_server(1027)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$Multiplayer.hide()


func _on_join_pressed():
	peer.create_client($Multiplayer/ServerIp.text, 1027)
	multiplayer.multiplayer_peer = peer
	$Multiplayer.hide()

func add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)


func exit_game(id):
	multiplayer.peer_disconnected.connect(delete_player)
	delete_player(id)
		
func delete_player(id):
	rpc("_delete_player", id)


@rpc("any_peer", "call_local")
func _delete_player(id):
	get_node(str(id)).queue_free()


func _on_area_3d_body_entered(body):
	print("Area Entered")
	if "health" in body:
		body.take_damage(1)


func _on_area_3d_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	print("Area Entered")
	if body.has("health"):
		body.take_damage(1)

func _on_area_3d_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	print("here")
	print(area)
