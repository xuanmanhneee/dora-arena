extends Node

const PORT = 7000
const MAX_CLIENT = 4

var peer: ENetMultiplayerPeer
var is_hosting := false

signal player_connected(id: int)
signal player_disconnected(id: int)
signal player_registered(id: int, player_name: String)


signal movement_input_received(id: int, move: int)
signal action_input_received(id: int, jump: bool, shoot: bool)


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int):
	player_connected.emit(id)
	print("[Peer connected]: id = %d" %id)

func _on_peer_disconnected(id: int):
	#player_disconnected.emit(id)
	EventBus.emit("lan_player_disconnected", [id])
	print("[Peer disconnected]: id = %d" %id)

func start_server() -> bool:
	if is_hosting:
		return true

	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENT)

	if error != OK:
		push_error("Không tạo được LAN server. Error: %s" % error)
		return false

	multiplayer.multiplayer_peer = peer
	is_hosting = true

	print("[LAN server started] Port = %d" % PORT)
	return true


func stop_server() -> void:
	if peer:
		peer.close()

	multiplayer.multiplayer_peer = null
	peer = null
	is_hosting = false

	print("[LAN server stopped]")

# RPC IMPLEMENTATIONS
@rpc("any_peer", "reliable")
func register(player_name: String, player_color: Color):
	if not multiplayer.is_server():
		return
	var id = multiplayer.get_remote_sender_id()

	EventBus.emit("player_register", [id, player_name, player_color])

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
