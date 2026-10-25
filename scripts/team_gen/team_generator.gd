class_name TeamGenerator
extends Node

@export var cost_brackets: Array[EnchantmentCostBracket]

var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()

	var team = generate_random_team(5, 8)
	print(team.map(func(e): return e.display_name))

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

# Can't have typed array here in the parameter, because the list of team has to be Array[Array] and not Array[Array[int]] because godot doesn't support nested generic typing like that
func calculate_team_weight(team_costs: Array) -> float:
	var weight = 1.0
	for cost in team_costs:
		var bracket_index = cost_brackets.find_custom(func(b): return b.cost == cost)
		weight *= cost_brackets[bracket_index].weight
	return weight

func choose_enchantment_in_bracket(bracket_cost: int) -> Enchantment:
	var bracket_index = cost_brackets.find_custom(func(b): return b.cost == bracket_cost)
	var enchantments = cost_brackets[bracket_index].enchantments
	return enchantments[rng.randi_range(0, enchantments.size() - 1)]

func generate_random_team(max_size: int, total_cost: int) -> Array[Enchantment]:
	var valid_costs: Array[int] = []
	valid_costs.assign(cost_brackets.map(func(bracket): return bracket.cost))
	var valid_teams = enumerate_unordered_teams(max_size, valid_costs, total_cost)	
	var team_weights = valid_teams.map(calculate_team_weight)
	
	print("Possible team plans:")
	for i in range(valid_teams.size()):
		print("%s | weight %s" % [valid_teams[i], team_weights[i]])
		
	var team_index = rng.rand_weighted(team_weights)
	print("Chosen team %s" % [valid_teams[team_index]])
	
	var team: Array[Enchantment] = []
	team.assign(valid_teams[team_index].map(choose_enchantment_in_bracket))
	team.shuffle()
	
	return team
