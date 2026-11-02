class_name EnchantmentHail
extends Enchantment

@export var chilled_effect: BattleStatusEffect

func after_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var opponents = cats.get_opposing_team(cats.get_cat_team(self_cat))
	for target in opponents:
		if target.health > 0:
			target.add_status_effect(chilled_effect, 2)
