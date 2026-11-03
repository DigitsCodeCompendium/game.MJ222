class_name EnchantmentMud
extends Enchantment

func before_death(cats: BattleCatsManager, self_cat: BattleCat):
	var target = cats.get_back_adjacent_cat(self_cat)
	if target == null or target.health <= 0:
		return
	target.attack += 1
	target.health += 2
	cats.notify_ability_activated(self_cat)
