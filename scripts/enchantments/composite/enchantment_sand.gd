class_name EnchantmentSand
extends Enchantment

@export var sand_shroud_move_duration = 0.4
@export var shrouded_effect: BattleStatusEffect

func before_ally_death(cats: BattleCatsManager, self_cat: BattleCat, ally_cat: BattleCat):
	if self_cat.shroud_ability_used:
		return
	
	var team: Array[BattleCat] = cats.get_cat_team(self_cat)
	var index = team.find(ally_cat)
	if index < 0:
		return
	if index + 1 < team.size():
		var target = team[index + 1]
		if target.add_status_effect(shrouded_effect):
			self_cat.shroud_ability_used = true
			cats.notify_ability_activated(self_cat)
			var effect_visual = target.get_status_visual(shrouded_effect.status_id)
			if effect_visual != null:
				var tween = effect_visual.create_tween()
				tween.tween_property(effect_visual, "global_position", target.global_position, sand_shroud_move_duration).from(self_cat.global_position)
				await tween.finished
