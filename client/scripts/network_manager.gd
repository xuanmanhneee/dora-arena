extends Node

const CONNECTION_SCENE := "res://scenes/connection_scene.tscn"
const LOBBY_SCENE := "res://scenes/lobby.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)


func connect_to_server(ip_address: String, port: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip_address, port)

	if err != OK:
		print("[Create client failed]: ", err)
		return

	multiplayer.multiplayer_peer = peer


func disconnect_from_server() -> void:
	_clear_peer()
	get_tree().change_scene_to_file(CONNECTION_SCENE)


func _clear_peer() -> void:
	if multiplayer.multiplayer_peer == null:
		return

	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null


func _on_connected() -> void:
	get_tree().change_scene_to_file(LOBBY_SCENE)


func _on_server_disconnected() -> void:
	print("[Server disconnected]")
	_clear_peer()
	get_tree().change_scene_to_file(CONNECTION_SCENE)


func _on_connection_failed() -> void:
	print("[Connection failed]")
	_clear_peer()
	get_tree().change_scene_to_file(CONNECTION_SCENE)


@rpc("authority", "reliable")
func start_game() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)


@rpc("any_peer", "reliable")
func register(_player_name: String, _player_color: Color) -> void:
	pass


@rpc("any_peer", "reliable")
func send_movement_input(_move: int) -> void:
	pass


@rpc("any_peer", "reliable")
func send_action_input(_action: int) -> void:
	pass
