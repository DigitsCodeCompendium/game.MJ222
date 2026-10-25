class_name EnchantmentElectric
extends Enchantment

func after_ally_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var opponent_team = cats.get_opposing_team(cats.get_cat_team(self_cat))
	
	var target = opponent_team[randi() % opponent_team.size()]
	target.take_damage(1)
	
