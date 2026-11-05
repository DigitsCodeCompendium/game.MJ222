class_name EnchantmentEarthquake
extends Enchantment

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	var opponents = cats.get_opposing_team(cats.get_cat_team(self_cat))
	var activated = _swap_pair(cats, opponents, 0, 1)
	# With fewer than four enemies the two pairs would overlap.
	if opponents.size() >= 4:
		activated = _swap_pair(cats, opponents, opponents.size() - 2, opponents.size() - 1) or activated
	if activated:
		cats.notify_ability_activated(self_cat)

func _swap_pair(cats: BattleCatsManager, team: Array[BattleCat], first: int, second: int) -> bool:
	if second >= team.size():
		return false
	var first_movable = cats.can_move_by_ability(team[first])
	var second_movable = cats.can_move_by_ability(team[second])
	if not first_movable or not second_movable:
		return false
	var original = team[first]
	var other = team[second]
	team[first] = team[second]
	team[second] = original
	cats.refresh_status_effect_auras()
	cats.notify_ability_movement(original)
	cats.notify_ability_movement(other)
	return true
