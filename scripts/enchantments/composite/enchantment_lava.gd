class_name EnchantmentLava
extends Enchantment

func after_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var opponent_team: Array[BattleCat] = cats.get_opposing_team(cats.get_cat_team(self_cat))
	
	# If the opposing team has at least 2 members, the first cat can be pushed to collide with the second cat
	if opponent_team.size() >= 2:
		if opponent_team[0].enchantment.can_be_moved_in_battle():
			opponent_team[0].take_damage(1)
	
	# If the opposing team has at least 3 members, the second cat can be pushed to collide with the third cat
	if opponent_team.size() >= 3:
		if opponent_team[1].enchantment.can_be_moved_in_battle():
			opponent_team[1].take_damage(1)
