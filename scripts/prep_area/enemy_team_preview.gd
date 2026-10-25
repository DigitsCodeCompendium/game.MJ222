extends Label

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.seed = GameManager.enemy_seed
	var game_progress = float(GameManager.stage_index) / (GameManager.total_rounds - 1)
	var team = TeamGenerator.generate_random_team(rng, 5, GameManager.enemy_team_cost, game_progress, GameManager.enemy_extra_cost)
	text = "Opponent team: %s" % TeamGenerator.describe_team(team)
