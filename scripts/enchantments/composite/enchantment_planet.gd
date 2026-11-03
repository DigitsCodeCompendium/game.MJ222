class_name EnchantmentPlanet
extends Enchantment

@export var rings_effect: BattleStatusEffect
@export var fragment_enchantment: Enchantment

func refresh_battle_passives(cats: BattleCatsManager, self_cat: BattleCat) -> void:
	var rear = cats.get_back_adjacent_cat(self_cat)
	var elements = _base_elements(rear.enchantment if rear != null else null)
	var bonus = 10 if &"earth" in elements else 0
	var old_bonus: int = self_cat.ability_state.get(&"planet_earth_bonus", 0)
	self_cat.ability_state[&"planet_elements"] = elements
	self_cat.ability_state[&"planet_earth_bonus"] = bonus
	self_cat.attack += bonus - old_bonus

func before_death(cats: BattleCatsManager, self_cat: BattleCat):
	refresh_battle_passives(cats, self_cat)
	var elements: PackedStringArray = self_cat.ability_state.get(&"planet_elements", PackedStringArray())
	var rear = cats.get_back_adjacent_cat(self_cat)
	# Give Rings to the original next ally, before inserting summoned Fragments.
	if "water" in elements and rear != null and rear.health > 0:
		rear.add_status_effect(rings_effect)
	if "fire" in elements and fragment_enchantment != null:
		var team = cats.get_cat_team(self_cat)
		var index = team.find(self_cat)
		if index < 0:
			return
		for _i in range(2):
			cats.queue_summon(team, "Fragment", fragment_enchantment, 5, 5, self_cat, index, rear)

func on_battle_enchantment_removed(self_cat: BattleCat) -> void:
	self_cat.attack -= int(self_cat.ability_state.get(&"planet_earth_bonus", 0))

func _base_elements(enchantment: Enchantment) -> PackedStringArray:
	var result: PackedStringArray = []
	var pending: Array[Enchantment] = []
	var visited: Dictionary = {}
	if enchantment != null:
		pending.append(enchantment)
	while not pending.is_empty():
		var current: Enchantment = pending.pop_back()
		if visited.has(current):
			continue
		visited[current] = true
		var element = ""
		if current is EnchantmentEarth:
			element = "earth"
		elif current is EnchantmentWater:
			element = "water"
		elif current is EnchantmentFire:
			element = "fire"
		elif current is EnchantmentAir:
			element = "air"
		if not element.is_empty() and not element in result:
			result.append(element)
		for component in [current.component1, current.component2]:
			if component != null:
				pending.append(component)
	return result
