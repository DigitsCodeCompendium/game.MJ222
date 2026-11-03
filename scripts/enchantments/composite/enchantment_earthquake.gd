class_name EnchantmentEarthquake
extends Enchantment

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	var opponents = cats.get_opposing_team(cats.get_cat_team(self_cat))
	_swap_pair(cats, opponents, 0, 1)
	# With fewer than four enemies the two pairs would overlap.
	if opponents.size() >= 4:
		_swap_pair(cats, opponents, opponents.size() - 2, opponents.size() - 1)

func _swap_pair(cats: BattleCatsManager, team: Array[BattleCat], first: int, second: int) -> void:
	if second >= team.size():
		return
	if not team[first].can_be_moved_in_battle() or not team[second].can_be_moved_in_battle():
		return
	var original = team[first]
	team[first] = team[second]
	team[second] = original
	cats.refresh_status_effect_auras()
