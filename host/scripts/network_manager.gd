extends Node

const PORT = 7000
const MAX_CLIENT = 4

signal player_connected(id: int)
signal player_disconnected(id: int)
signal player_registered(id: int, player_name: String)


signal movement_input_received(id: int, move: int)
signal action_input_received(id: int, jump: bool, shoot: bool)

func _ready() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int):
	player_connected.emit(id)
	print("[Peer connected]: id = %d" %id)

func _on_peer_disconnected(id: int):
	player_disconnected.emit(id)
	print("[Peer disconnected]: id = %d" %id)

# RPC IMPLEMENTATIONS
@rpc("any_peer", "reliable")
func register(_player_name: String):
	if not multiplayer.is_server():
		return
	var id = multiplayer.get_remote_sender_id()
	print("[Player register]: %s" % _player_name)
	player_registered.emit(id, _player_name)

@rpc("any_peer", "unreliable")
func send_movement_input(move: int):
	if not multiplayer.is_server():
		return
	
	if not Enums.is_valid_movement(move):
		return
	
	var id = multiplayer.get_remote_sender_id()
	movement_input_received.emit(id, move)

@rpc("any_peer", "reliable")
func send_action_input(action: int):
	if not multiplayer.is_server():
		return
		
	if not Enums.is_valid_action(action):
		return
	
	var id = multiplayer.get_remote_sender_id()
	action_input_received.emit(id, action)

# RPC STUB
@rpc("authority", "reliable")
func start_game():
	pass
