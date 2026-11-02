class_name EnchantmentPermafrost
extends Enchantment

@export var chilled_effect: BattleStatusEffect

func after_attack(_cats: BattleCatsManager, self_cat: BattleCat):
	var target = self_cat.last_attack_target
	if is_instance_valid(target) and target.health > 0:
		target.add_status_effect(chilled_effect)

func before_death(cats: BattleCatsManager, self_cat: BattleCat):
	if self_cat.preservation_used:
		return
	var opponents = cats.get_opposing_team(cats.get_cat_team(self_cat))
	if opponents.is_empty():
		return
	var consumed = opponents[0].consume_status_effect_stacks(chilled_effect.status_id, 3)
	if consumed > 0:
		self_cat.preservation_used = true
		self_cat.health = consumed * 2
