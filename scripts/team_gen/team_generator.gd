extends Node

const PRICES = preload("res://scripts/game_prices.gd")

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
func calculate_team_weight(team_costs: Array, weight_t: float) -> float:
	var weight = 1.0
	for cost in team_costs:
		var bracket = find_cost_bracket(cost)
		weight *= lerpf(bracket.weight_early, bracket.weight_late, weight_t)
	return weight

## total_cost and extra_coins are coin budgets, not numbers of stat upgrades.
func generate_random_team(rng: RandomNumberGenerator, max_size: int, total_cost: int, weight_t: float, extra_coins: int = 0, spawn_rules: StageSpawnRules = null) -> Array[CatData]:
	print("Generating team: max_size %s, total_cost %s, weight_t %1.3f, extra_coins %s" % [max_size, total_cost, weight_t, extra_coins])
	print("RNG seed %x, state %x" % [rng.seed, rng.state])
	if max_size <= 0 or total_cost <= 0:
		return []
	var valid_costs: Array[int] = []
	var enchantments_by_cost: Dictionary = {}
	for bracket in cost_brackets:
		var allowed: Array[Enchantment] = []
		for enchantment in bracket.enchantments:
			if enchantment != null and (spawn_rules == null or spawn_rules.allows(enchantment)):
				allowed.append(enchantment)
		if bracket.cost > 0 and not allowed.is_empty():
			valid_costs.append(bracket.cost)
			enchantments_by_cost[bracket.cost] = allowed
	if valid_costs.is_empty():
		return []
	# Prices 1/4/10 leave gaps with five slots. Buy the most expensive affordable
	# composition, then spend leftover coins on upgrades at the player's price.
	var base_cost = mini(total_cost, max_size * valid_costs.max())
	var valid_teams = enumerate_unordered_teams(max_size, valid_costs, base_cost)
	while valid_teams.is_empty() and base_cost > 0:
		base_cost -= 1
		valid_teams = enumerate_unordered_teams(max_size, valid_costs, base_cost)
	if base_cost == 0:
		return []
	var team_weights = valid_teams.map(func(t): return calculate_team_weight(t, clampf(weight_t, 0, 1)))
	# Some high-tier compositions have zero early-game weight. They must remain
	# usable if every affordable composition would otherwise have weight zero.
	if team_weights.all(func(weight): return weight <= 0.0):
		team_weights.fill(1.0)
	var team_index = rng.rand_weighted(team_weights)
	var team: Array[CatData] = []
	for team_member_cost in valid_teams[team_index]:
		var cat_data = CatData.new()
		cat_data.attack_offset = 0
		cat_data.health_offset = 0
		var allowed: Array = enchantments_by_cost[team_member_cost]
		cat_data.enchantment = allowed[rng.randi_range(0, allowed.size() - 1)]
		team.append(cat_data)
	var upgrade_coins = total_cost - base_cost + maxi(0, extra_coins)
	var upgrade_count = floori(float(upgrade_coins) / PRICES.UPGRADE)
	for _i in range(upgrade_count):
		var target_index = rng.randi_range(0, team.size() - 1)
		team[target_index].attack_offset += 1
		team[target_index].health_offset += 1
	return team

func get_max_possible_team_cost(team_size: int):
	var max_cost = 0
	for bracket in cost_brackets:
		if bracket.cost > max_cost:
			max_cost = bracket.cost
	return max_cost * team_size

# Note: Only works well for teams generated here!
func describe_team(team: Array[CatData]) -> String:
	return ", ".join(team.map(describe_team_member))

func describe_team_member(cat: CatData) -> String:
	var result = cat.enchantment.display_name
	# Teams generated here always have the same attack and health offset
	if cat.attack_offset > 0:
		result += "+%s" % cat.attack_offset
	return result
