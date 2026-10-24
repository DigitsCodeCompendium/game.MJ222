class_name EnchantmentSand
extends Enchantment

func before_ally_death(cats: BattleCatsManager, self_cat: BattleCat, ally_cat: BattleCat):
	if self_cat.shroud_ability_used:
		return
	
	var team: Array[BattleCat] = cats.get_cat_team(self_cat)
	var index = team.find(ally_cat)
	if index < 0:
		return
	if index + 1 < team.size():
		team[index + 1].is_shrouded = true
		self_cat.shroud_ability_used = true
