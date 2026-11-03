class_name EnchantmentMeteorite
extends Enchantment

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	var damage = maxi(0, floori(float(self_cat.attack) / 3.0))
	if damage == 0:
		return
	for target in cats.get_all_cats():
		cats.deal_ability_damage(self_cat, target, damage)
	cats.notify_ability_activated(self_cat)
