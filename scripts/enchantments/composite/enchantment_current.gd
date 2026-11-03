class_name EnchantmentCurrent
extends Enchantment

func after_dealing_damage(cats: BattleCatsManager, self_cat: BattleCat, _target: BattleCat, amount: int) -> void:
	if amount <= 0:
		return
	var applied = false
	for ally in cats.get_cat_team(self_cat):
		if ally.health > 0 and (ally.enchantment.count_base_element(&"fire") > 0 or ally.enchantment.count_base_element(&"air") > 0):
			ally.attack += 1
			ally.health += 1
			applied = true
	if applied:
		cats.notify_ability_activated(self_cat)
