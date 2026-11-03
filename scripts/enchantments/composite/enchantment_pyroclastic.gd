class_name EnchantmentPyroclastic
extends EnchantmentLava

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	var team = cats.get_cat_team(self_cat)
	var index = team.find(self_cat)
	if index > 0:
		team.remove_at(index)
		team.push_front(self_cat)
		cats.refresh_status_effect_auras()
