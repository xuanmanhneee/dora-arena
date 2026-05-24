
extends Node

signal player_died(body: Node)

signal score_changed(team: Enums.Team, score: int)
signal time_changed(remaining_time: int)
signal game_over(winner_team: int)
signal phase_changed

signal player_pickup_item(player: Player)

signal play_again_requested
signal return_main_menu_requested

signal game_restarted

signal energy_changed(player: Player, current: float, maximum: float)
signal player_score_changed(player: Player, score: int)
