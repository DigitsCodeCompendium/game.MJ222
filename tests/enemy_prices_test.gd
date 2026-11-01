extends SceneTree
const Prices = preload("res://scripts/game_prices.gd")
func _initialize() -> void:
	call_deferred("run")
func upgrade_count(team: Array) -> int:
	var count=0
	for member in team:
		assert(member.attack_offset==member.health_offset)
		assert(member.attack_offset>=0)
		count+=member.attack_offset
	return count
func team_cost(generator:Node,team:Array) -> int:
	var coins=0
	for member in team:
		var found=false
		for bracket in generator.cost_brackets:
			if member.enchantment in bracket.enchantments:
				coins+=bracket.cost
				found=true
				break
		assert(found)
	return coins+upgrade_count(team)*Prices.UPGRADE
func run() -> void:
	var generator=root.get_node("TeamGenerator")
	assert(Prices.TIER_1==4 and Prices.TIER_2==10 and Prices.UPGRADE==3)
	assert(generator.find_cost_bracket(Prices.CAT).base_attack==1)
	assert(generator.find_cost_bracket(Prices.TIER_1).base_attack==2)
	assert(generator.find_cost_bracket(Prices.TIER_2).base_attack==4)
	assert(generator.get_max_possible_team_cost(5)==50)
	var cookie=load("res://scenes/prep_area/cookie_jar.tscn").instantiate()
	assert(cookie.get("cookie_price")==null, "Cookie price must not be overridable")
	cookie.free()
	# Every tier is derived from game_prices; costs are not serialized overrides.
	var bracket_script=load("res://scripts/team_gen/enchantment_cost_bracket.gd")
	var tier_prices=[Prices.CAT,Prices.TIER_1,Prices.TIER_2,Prices.TIER_3,Prices.TIER_4]
	for tier in range(tier_prices.size()):
		var bracket=bracket_script.new()
		bracket.tier=tier
		assert(bracket.cost==tier_prices[tier])
		for property in bracket.get_property_list():
			if property.name=="cost":
				assert(not property.usage & PROPERTY_USAGE_EDITOR)
				assert(not property.usage & PROPERTY_USAGE_STORAGE)
	var random=RandomNumberGenerator.new()
	var budgets=range(1,61)+[99,150,218]
	for budget in budgets:
		for weight in [0.0,0.5,1.0]:
			for seed_number in range(3):
				random.seed=seed_number
				var base=mini(budget,50)
				var team=generator.generate_random_team(random,5,base,weight,maxi(0,budget-base))
				assert(team.size()>0 and team.size()<=5)
				var spent=team_cost(generator,team)
				assert(spent<=budget,"Enemy overspent")
				assert(budget-spent<Prices.UPGRADE,"Left enough coins for another upgrade")
	for budget in range(50,57):
		random.seed=42
		var team=generator.generate_random_team(random,5,50,0.0,budget-50)
		assert(team.size()==5)
		assert(upgrade_count(team)==floori(float(budget-50)/3.0))
		for member in team:
			assert(member.enchantment in generator.find_cost_bracket(10).enchantments)
	random.seed=42
	var gap=generator.generate_random_team(random,5,49,0.0)
	assert(team_cost(generator,gap)==47 and upgrade_count(gap)==1)
	assert(generator.generate_random_team(random,5,0,0.0).is_empty())
	assert(generator.generate_random_team(random,0,10,0.0).is_empty())
	random.seed=93
	var first=generator.describe_team(generator.generate_random_team(random,5,50,0.7,19))
	random.seed=93
	var second=generator.describe_team(generator.generate_random_team(random,5,50,0.7,19))
	assert(first==second)
	print("ENEMY PRICES PASSED: 567 BUDGET/WEIGHT/SEED COMBINATIONS, 1/4/10 TIERS, THREE-COIN UPGRADES, GAPS AND DETERMINISM")
	quit()
