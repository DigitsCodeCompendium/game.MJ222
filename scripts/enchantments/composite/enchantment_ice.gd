class_name EnchantmentIce
extends Enchantment

@export var chilled_effect: BattleStatusEffect

func before_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var opponents = cats.get_opposing_team(cats.get_cat_team(self_cat))
	if opponents.is_empty():
		return
	var target = opponents[0]
	var stacks = target.get_status_effect_stacks(chilled_effect.status_id)
	if stacks > 0:
		self_cat.normal_attack_bonus += stacks
		target.consume_status_effect_stacks(chilled_effect.status_id)

func after_attack(_cats: BattleCatsManager, self_cat: BattleCat):
	var target = self_cat.last_attack_target
	if is_instance_valid(target) and target.health > 0:
		target.add_status_effect(chilled_effect)
