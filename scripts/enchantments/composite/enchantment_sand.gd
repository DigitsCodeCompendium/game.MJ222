class_name EnchantmentSand
extends Enchantment

@export var sand_shroud_move_duration = 0.4

func before_ally_death(cats: BattleCatsManager, self_cat: BattleCat, ally_cat: BattleCat):
	if self_cat.shroud_ability_used:
		return
	
	var team: Array[BattleCat] = cats.get_cat_team(self_cat)
	var index = team.find(ally_cat)
	if index < 0:
		return
	if index + 1 < team.size():
		if not team[index + 1].is_shrouded:
			team[index + 1].is_shrouded = true
			team[index + 1].sand_shroud.visible = true
			self_cat.shroud_ability_used = true
			
			var tween = cats.create_tween()
			tween.tween_property(team[index + 1].sand_shroud, "global_position", team[index + 1].global_position, sand_shroud_move_duration).from(self_cat.sand_shroud.global_position)
			await tween.finished
