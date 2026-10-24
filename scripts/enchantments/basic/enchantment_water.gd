class_name EnchantmentWater
extends Enchantment

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	var team = cats.cats_left if self_cat in cats.cats_left else cats.cats_right
	
	for cat in team:
		if cat.enchantment == self or cat.enchantment.component1 == self or cat.enchantment.component2 == self:
			self_cat.attack += 1
