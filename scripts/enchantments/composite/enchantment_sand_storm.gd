class_name EnchantmentSandStorm
extends Enchantment

@export var shrouded_effect: BattleStatusEffect

func before_attack(cats: BattleCatsManager, self_cat: BattleCat):
	if self_cat.ability_state.get(&"sand_storm_used", false):
		return
	self_cat.ability_state[&"sand_storm_used"] = true
	var opponents = cats.get_opposing_team(cats.get_cat_team(self_cat)).duplicate()
	var damage = maxi(0, floori(float(self_cat.attack) / 2.0))
	for target in opponents:
		if target.health > 0:
			cats.deal_ability_damage(self_cat, target, damage)
	for target in opponents:
		if target.health > 0:
			target.add_status_effect(shrouded_effect)
	cats.notify_ability_activated(self_cat)
