class_name EnchantmentSolarFlare
extends Enchantment

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	var applied = false
	for ally in cats.get_cat_team(self_cat):
		var fire_count = ally.enchantment.count_base_element(&"fire")
		if fire_count > 0:
			ally.attack += fire_count * 3
			applied = true
	if applied:
		cats.notify_ability_activated(self_cat)
