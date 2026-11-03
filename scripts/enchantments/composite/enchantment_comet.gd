class_name EnchantmentComet
extends Enchantment

@export var inspired_effect: BattleStatusEffect

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	var activated = false
	for ally in cats.get_cat_team(self_cat):
		if not ally.has_made_normal_attack:
			activated = ally.add_status_effect(inspired_effect) or activated
	if activated:
		cats.notify_ability_activated(self_cat)
