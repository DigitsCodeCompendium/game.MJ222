class_name EnchantmentStorm
extends Enchantment

func after_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var opponent_team: Array[BattleCat] = cats.get_opposing_team(cats.get_cat_team(self_cat))
	
	if opponent_team.size() >= 2:
		var last_opponent = opponent_team[opponent_team.size() - 1]
		if cats.can_move_by_ability(last_opponent):
			opponent_team.remove_at(opponent_team.size() - 1)
			opponent_team.insert(0, last_opponent)
			cats.refresh_status_effect_auras()
			cats.notify_ability_movement(last_opponent)
			cats.notify_ability_activated(self_cat)
