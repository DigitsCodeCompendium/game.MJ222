class_name TeamGenerator
extends Node

@export var cost_brackets: Array[EnchantmentCostBracket]

var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()

	var team = generate_random_team(5, 3, 8, 1)
	print(team.map(func(cd): return "Attack %s Health %s Enchantment %s" % [cd.base_attack, cd.base_health, cd.enchantment.display_name]))

# it's best to arrange valid_costs in decreasing order, though it should still produce the same results regardless
func enumerate_unordered_teams(max_size: int, valid_costs: Array[int], total_cost: int) -> Array[Array]:
	if total_cost <= 0:
		return [[]]
	
	# We can never match the required cost here
	if valid_costs.size() <= 0 or max_size * valid_costs.max() < total_cost:
		return []

	var teams: Array[Array] = []
	for cost_index in range(valid_costs.size()):
		var cost = valid_costs[cost_index]
		if cost > total_cost:
			continue
		var sub_teams = enumerate_unordered_teams(max_size - 1, valid_costs.slice(cost_index), total_cost - cost)
		for sub_team in sub_teams:
			teams.append([cost] + sub_team)
	return teams

func find_cost_bracket(cost: int) -> EnchantmentCostBracket:
	for bracket in cost_brackets:
		if bracket.cost == cost:
			return bracket
	return null

# Can't have typed array here in the parameter, because the list of team has to be Array[Array] and not Array[Array[int]] because godot doesn't support nested generic typing like that
func calculate_team_weight(team_costs: Array, weight_progress: float) -> float:
	var weight = 1.0
	for cost in team_costs:
		var bracket = find_cost_bracket(cost)
		weight *= lerpf(bracket.weight_early, bracket.weight_late, weight_progress)
	return weight

func generate_random_team(max_size: int, max_cost: int, total_cost: int, weight_progress: float) -> Array[CatData]:
	var valid_costs: Array[int] = []
	valid_costs.assign(cost_brackets.map(func(bracket): return bracket.cost).filter(func(cost): return cost <= max_cost))
	var valid_teams = enumerate_unordered_teams(max_size, valid_costs, total_cost)	
	var team_weights = valid_teams.map(func(team): return calculate_team_weight(team, weight_progress))
	
	print("Possible team plans:")
	for i in range(valid_teams.size()):
		print("%s | weight %s" % [valid_teams[i], team_weights[i]])
		
	var team_index = rng.rand_weighted(team_weights)
	print("Chosen team %s" % [valid_teams[team_index]])
	
	var team: Array[CatData] = []
	for team_member_cost in valid_teams[team_index]:
		var cat_data = CatData.new()
		var bracket = find_cost_bracket(team_member_cost)
		cat_data.base_attack = bracket.base_attack
		cat_data.base_health = bracket.base_health
		cat_data.enchantment = bracket.enchantments[rng.randi_range(0, bracket.enchantments.size() - 1)]
		team.append(cat_data)
	
	return team
