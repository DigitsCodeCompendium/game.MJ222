class_name EnchantmentLava
extends Enchantment

@export var push_animation_distance: float = 2
@export var push_animation_duration: float = 0.4

func after_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var opponent_team: Array[BattleCat] = cats.get_opposing_team(cats.get_cat_team(self_cat))
	
	# If the opposing team has at least 2 members, the first cat can be pushed to collide with the second cat
	if opponent_team.size() >= 2:
		if opponent_team[0].enchantment.can_be_moved_in_battle():
			opponent_team[0].take_damage(1)
			await animate_move(opponent_team[0])
	
	# If the opposing team has at least 3 members, the second cat can be pushed to collide with the third cat
	if opponent_team.size() >= 3:
		if opponent_team[1].enchantment.can_be_moved_in_battle():
			opponent_team[1].take_damage(1)
			await animate_move(opponent_team[1])

func animate_move(cat: BattleCat):
	var start_pos = cat.position
	var hit_pos = cat.transform * Vector3(0, 0, push_animation_distance)
	var tween = cat.create_tween()
	tween.tween_property(cat, "position", start_pos + hit_pos, push_animation_duration / 2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(cat, "position", start_pos, push_animation_duration / 2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tween.finished
	
