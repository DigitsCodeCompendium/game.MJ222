class_name EnchantmentDune
extends Enchantment

const DEFAULT_WORM = preload("res://resources/enchantments/special/worm.tres")
@export var worm_enchantment: Enchantment = DEFAULT_WORM

func before_death(cats: BattleCatsManager, self_cat: BattleCat):
	if self_cat.ability_state.get(&"dune_swallowed", false):
		return
	self_cat.ability_state[&"dune_swallowed"] = true
	var team = cats.get_cat_team(self_cat)
	var index = team.find(self_cat)
	if index < 0:
		return
	var victims: Array[BattleCat] = [self_cat]
	var front = cats.get_front_adjacent_cat(self_cat)
	var back = cats.get_back_adjacent_cat(self_cat)
	if front != null:
		victims.append(front)
	if back != null:
		victims.append(back)
	cats.swallow_into_worm(self_cat, victims, worm_enchantment if worm_enchantment != null else DEFAULT_WORM)
