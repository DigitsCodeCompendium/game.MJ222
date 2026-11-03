class_name EnchantmentAir
extends Enchantment

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	super.after_battle_start(cats, self_cat)

	var team = cats.get_cat_team(self_cat)
	
	for cat in team:
		self_cat.health += cat.enchantment.count_base_element(&"air")
	cats.notify_ability_activated(self_cat)
