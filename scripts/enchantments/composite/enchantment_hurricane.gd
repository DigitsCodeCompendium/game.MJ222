class_name EnchantmentHurricane
extends Enchantment

@export var shrouded_effect: BattleStatusEffect

func after_normal_attack_received(cats: BattleCatsManager, self_cat: BattleCat) -> void:
	var team = cats.get_cat_team(self_cat)
	if self_cat.health <= 0 or team.size() < 2 or team.front() != self_cat:
		return
	if not cats.move_to_back_by_ability(self_cat):
		return
	# A simultaneously fainted teammate cannot receive the protection.
	for ally in team:
		if ally != self_cat and ally.health > 0:
			ally.add_status_effect(shrouded_effect)
			break
	cats.notify_ability_activated(self_cat)
