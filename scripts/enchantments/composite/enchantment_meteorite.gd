class_name EnchantmentMeteorite
extends Enchantment

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	var damage = maxi(0, floori(float(self_cat.attack) / 3.0))
	if damage == 0:
		return
	for target in cats.get_all_cats():
		target.take_damage(damage)
