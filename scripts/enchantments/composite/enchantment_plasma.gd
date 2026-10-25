class_name EnchantmentPlasma
extends Enchantment

func after_battle_turn(cats: BattleCatsManager, self_cat: BattleCat):
	var front_cat = cats.get_front_adjacent_cat(self_cat)
	if front_cat != null:
		if front_cat.enchantment is EnchantmentElectric or front_cat.enchantment is EnchantmentStorm or front_cat.enchantment is EnchantmentSand:
			return
	
	var back_cat = cats.get_back_adjacent_cat(self_cat)
	if back_cat != null:
		if back_cat.enchantment is EnchantmentElectric or back_cat.enchantment is EnchantmentStorm or back_cat.enchantment is EnchantmentSand:
			return
	
	self_cat.health -= 1
	self_cat.attack -= 1
