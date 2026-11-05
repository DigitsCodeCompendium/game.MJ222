class_name EnchantmentLava
extends Enchantment

@export var push_animation_distance: float = 2
@export var push_animation_duration: float = 0.4
@export var collision_damage: int = 1
@export var push_all_enemies: bool = false

func after_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var opponent_team: Array[BattleCat] = cats.get_opposing_team(cats.get_cat_team(self_cat))
	
	var targets = opponent_team.duplicate()
	var count = targets.size() if push_all_enemies else mini(2, maxi(0, targets.size() - 1))
	var activated = false
	for i in range(count):
		var target: BattleCat = targets[i]
		if cats.can_move_by_ability(target):
			activated = true
			# The backmost enemy is pushed too, but has nothing behind it to hit.
			if i + 1 < targets.size():
				cats.deal_ability_damage(self_cat, target, collision_damage)
			await animate_move(target)
			cats.notify_ability_movement(target)
	if activated:
		cats.notify_ability_activated(self_cat)

func animate_move(cat: BattleCat):
	var start_pos = cat.position
	var hit_pos = cat.basis * Vector3(0, 0, push_animation_distance)
	var tween = cat.create_tween()
	tween.tween_property(cat, "position", start_pos + hit_pos, push_animation_duration / 2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(cat, "position", start_pos, push_animation_duration / 2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tween.finished
	
