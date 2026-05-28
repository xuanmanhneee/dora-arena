class_name Game
extends Node

@onready var world: Node2D = %World
@onready var game_manager: GameManager = %GameManager
@onready var item_manager: ItemManager = %ItemManager
@onready var game_camera: GameCamera = $Camera2D
@onready var overlay_layer: OverlayLayer = $OverlayLayer

var players: Dictionary[int, Player] = {}

var match_config: MatchConfig

var mode: Enums.GameMode
var game_time: float
var map_info: MapInfo
var current_map: Node2D
var player_configs: Dictionary[int, Dictionary] = {}

func _ready() -> void:
	_setup(GameData.match_config)
	_load_map()

	game_manager.setup(self)
	game_camera.setup(self)
	item_manager.setup(self)
	overlay_layer.setup(self)
	
	AnimatedCursor.hide_cursor()

func _setup(config: MatchConfig) -> void:
	match_config = config

	mode = config.mode
	game_time = config.game_time
	map_info = config.map_info
	player_configs = config.players.duplicate(true)

func _load_map() -> void:
	var packed_scene := load(map_info.scene_path) as PackedScene

	if packed_scene == null:
		push_error("Cannot load map")
		return

	current_map = packed_scene.instantiate() as Node2D
	world.add_child(current_map)
