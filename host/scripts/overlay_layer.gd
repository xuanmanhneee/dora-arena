extends CanvasLayer

@onready var team_a_score_label: Label = $ScoreBoards/TeamA/Label
@onready var team_b_score_label: Label = $ScoreBoards/TeamB/Label

func _ready() -> void:
	set_process(false)
	set_physics_process(false)

func _update_score(team: Enums.Team, score: int):
	if team == Enums.Team.TEAM_A:
		team_a_score_label.text = str(score)
	else:
		team_b_score_label.text = str(score)
