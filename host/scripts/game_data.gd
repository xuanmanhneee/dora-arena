extends Node

var current_game_time: float = 20

var player_teams: Dictionary[int, Enums.Team] = {}
var player_names: Dictionary[int, String] = {}
var mode: int

func reset():
	player_teams.clear()
	player_names.clear()
	mode = -1
