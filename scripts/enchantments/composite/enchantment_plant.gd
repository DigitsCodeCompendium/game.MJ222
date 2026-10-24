class_name EnchantmentPlant
extends Enchantment

@export var enchantment_cat: Enchantment

func before_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var front_cat = cats.get_front_adjacent_cat(self_cat)
	if front_cat != null:
		absorb_water(self_cat, front_cat)
	
	var back_cat = cats.get_back_adjacent_cat(self_cat)
	if back_cat != null:
		absorb_water(self_cat, back_cat)

func absorb_water(self_cat: BattleCat, target_cat: BattleCat):
	if target_cat.enchantment is EnchantmentWater:
		target_cat.set_enchantment(enchantment_cat)
		self_cat.health += 1
		self_cat.attack += 1
	elif target_cat.enchantment.component1 is EnchantmentWater:
		target_cat.set_enchantment(target_cat.enchantment.component2)
		self_cat.health += 1
		self_cat.attack += 1
	elif target_cat.enchantment.component2 is EnchantmentWater:
		target_cat.set_enchantment(target_cat.enchantment.component1)
		self_cat.health += 1
		self_cat.attack += 1
