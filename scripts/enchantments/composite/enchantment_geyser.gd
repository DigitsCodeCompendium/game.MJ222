class_name EnchantmentGeyser
extends Enchantment

@export var steam_enchantment: Enchantment

func before_death(cats: BattleCatsManager, self_cat: BattleCat):
	var team = cats.get_cat_team(self_cat)
	var index = team.find(self_cat)
	if index < 0:
		return
	var rear = cats.get_back_adjacent_cat(self_cat)
	for _i in range(3):
		cats.queue_summon(team, "Steam", steam_enchantment, 2, 2, self_cat, index, rear)
	cats.notify_ability_activated(self_cat)
