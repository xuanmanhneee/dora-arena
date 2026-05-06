extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected)

func connect_to_server(ip_address: String, port: int):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, port)
	multiplayer.multiplayer_peer = peer

func _on_connected():
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

@rpc("authority", "reliable")
func start_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

@rpc("any_peer", "reliable")
func register(_player_name: String):
	pass

@rpc("any_peer", "unreliable")
func send_movement_input(_move: int):
	pass

@rpc("any_peer", "reliable")
func send_action_input(_action: int):
	pass
