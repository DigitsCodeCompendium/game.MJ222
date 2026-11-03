class_name EnchantmentLightning
extends Enchantment

func after_ally_ability_activated(cats: BattleCatsManager, self_cat: BattleCat, _ally: BattleCat) -> void:
	if self_cat.ability_state.get(&"lightning_last_turn", -2) == cats.turn_index:
		return
	var opponents = cats.get_opposing_team(cats.get_cat_team(self_cat)).filter(func(cat): return cat.health > 0)
	if opponents.is_empty():
		return
	self_cat.ability_state[&"lightning_last_turn"] = cats.turn_index
	var target: BattleCat = opponents[GameManager.rng.randi_range(0, opponents.size() - 1)]
	cats.deal_ability_damage(self_cat, target, 2)
	cats.notify_ability_activated(self_cat)
