class_name EnchantmentWater
extends Enchantment

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	var team = cats.get_cat_team(self_cat)
	
	for cat in team:
		if cat.enchantment == self or cat.enchantment.component1 == self or cat.enchantment.component2 == self:
			self_cat.attack += 1
