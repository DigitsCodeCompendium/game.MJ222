class_name EnchantmentGlacier
extends Enchantment

@export var chilled_effect: BattleStatusEffect

func after_attack(_cats: BattleCatsManager, self_cat: BattleCat):
	var target = self_cat.last_attack_target
	if not is_instance_valid(target):
		return
	if target.consume_status_effect_stacks(chilled_effect.status_id) > 0:
		self_cat.health += 2
	if target.health > 0:
		target.add_status_effect(chilled_effect)
