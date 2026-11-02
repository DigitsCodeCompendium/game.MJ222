class_name EnchantmentSnow
extends Enchantment

@export var chilled_effect: BattleStatusEffect

func after_attack(_cats: BattleCatsManager, self_cat: BattleCat):
	var target = self_cat.last_attack_target
	if is_instance_valid(target) and target.health > 0:
		target.add_status_effect(chilled_effect)
