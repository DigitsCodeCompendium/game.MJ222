class_name EnchantmentVoid
extends Enchantment

func after_death(cats: BattleCatsManager, self_cat: BattleCat):
	for cat in cats.cats_left:
		cat.health -= 2
	for cat in cats.cats_right:
		cat.health -= 2
