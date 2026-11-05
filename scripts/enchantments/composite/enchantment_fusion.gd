class_name EnchantmentFusion
extends Enchantment

func before_attack(cats: BattleCatsManager, self_cat: BattleCat) -> void:
	var ally = cats.get_back_adjacent_cat(self_cat)
	if self_cat.health <= 0 or ally == null or ally.health <= 0:
		return
	# Count before damage reactions can change the ally or its enchantment.
	self_cat.normal_attack_bonus += ally.enchantment.count_base_element(&"fire")
	cats.deal_ability_damage(self_cat, ally, 1)
	cats.notify_ability_activated(self_cat)
