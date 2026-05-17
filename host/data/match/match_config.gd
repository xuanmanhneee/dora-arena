class_name MatchConfig
extends Resource

@export var mode: Enums.GameMode = Enums.GameMode.LOCAL_2P
@export var game_time: float = 60.0
@export var map_info: MapInfo

var players: Dictionary[int, Dictionary] = {}
