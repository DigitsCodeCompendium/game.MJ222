extends Node

@export var cost_brackets: Array[EnchantmentCostBracket]

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

func generate_random_team(rng: RandomNumberGenerator, max_size: int, total_cost: int, weight_progress: float, extra_points: int = 0) -> Array[CatData]:
	var valid_costs: Array[int] = []
	valid_costs.assign(cost_brackets.map(func(bracket): return bracket.cost))
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
		cat_data.attack_offset = 0
		cat_data.health_offset = 0
		cat_data.enchantment = bracket.enchantments[rng.randi_range(0, bracket.enchantments.size() - 1)]
		team.append(cat_data)
	
	for _i in range(extra_points):
		var target_index = rng.randi_range(0, team.size() - 1)
		team[target_index].attack_offset += 1
		team[target_index].health_offset += 1
	
	return team

# Note: Only works well for teams generated here!
func describe_team(team: Array[CatData]) -> String:
	return ", ".join(team.map(describe_team_member))

func describe_team_member(cat: CatData) -> String:
	var result = cat.enchantment.display_name
	# Teams generated here always have the same attack and health offset
	if cat.attack_offset > 0:
		result += "+%s" % cat.attack_offset
	return result
