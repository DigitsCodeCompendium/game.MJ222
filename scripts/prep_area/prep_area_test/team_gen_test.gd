extends Control

var target_cost: int
var seed: int

func _ready():
	target_cost = $GridContainer/TargetCostEdit.text.to_int()
	
	$GridContainer/TargetCostEdit.text_submitted.connect(_on_target_cost_submitted)
	$GridContainer/SeedEdit.text_submitted.connect(_on_seed_submitted)

func _on_target_cost_submitted(value: String):
	if value.is_valid_int():
		if target_cost != value.to_int():
			target_cost = value.to_int()
			_refresh_team()
	else:
		$GridContainer/TargetCostEdit.text = str(target_cost)

func _on_seed_submitted(value: String):
	if value.is_valid_int():
		seed = value.to_int()
	else:
		seed = value.hash()
	
	_refresh_team()

func _refresh_team():
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	var team = TeamGenerator.generate_random_team(rng, 5, target_cost, 0.2, 0)
	$ExpectedTeamLabel.text = TeamGenerator.describe_team(team)
