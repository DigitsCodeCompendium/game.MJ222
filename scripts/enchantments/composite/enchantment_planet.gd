class_name EnchantmentPlanet
extends Enchantment

@export var rings_effect: BattleStatusEffect
@export var fragment_enchantment: Enchantment

func after_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var rear = cats.get_back_adjacent_cat(self_cat)
	var elements = _base_elements(rear.enchantment if rear != null else null)
	var earth_count: int = elements[&"earth"]
	var air_count: int = elements[&"air"]
	var activated = false
	if earth_count > 0:
		self_cat.health += earth_count
		activated = true
	for _i in range(air_count):
		var opponents = cats.get_opposing_team(cats.get_cat_team(self_cat)).filter(func(cat): return cat.health > 0)
		if opponents.is_empty():
			break
		var target: BattleCat = opponents[GameManager.rng.randi_range(0, opponents.size() - 1)]
		cats.deal_ability_damage(self_cat, target, 1)
		activated = true
	if activated:
		cats.notify_ability_activated(self_cat)

func before_death(cats: BattleCatsManager, self_cat: BattleCat):
	var rear = cats.get_back_adjacent_cat(self_cat)
	var elements = _base_elements(rear.enchantment if rear != null else null)
	# Give Rings to the original next ally, before inserting summoned Fragments.
	var activated = false
	var water_count: int = elements[&"water"]
	var fire_count: int = elements[&"fire"]
	if water_count > 0 and rear != null and rear.health > 0:
		activated = rear.add_status_effect(rings_effect, water_count)
	if fire_count > 0 and fragment_enchantment != null:
		var team = cats.get_cat_team(self_cat)
		var index = team.find(self_cat)
		if index < 0:
			return
		var attack = fragment_enchantment.base_attack + fire_count
		var health = fragment_enchantment.base_health + fire_count
		for _i in range(2):
			cats.queue_summon(team, "Fragment", fragment_enchantment, attack, health, self_cat, index, rear)
		activated = true
	if activated:
		cats.notify_ability_activated(self_cat)

func _base_elements(enchantment: Enchantment) -> Dictionary:
	var result = {}
	for element in [&"earth", &"water", &"fire", &"air"]:
		result[element] = enchantment.count_base_element(element) if enchantment != null else 0
	return result
