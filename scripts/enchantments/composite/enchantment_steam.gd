class_name EnchantmentSteam
extends Enchantment

func handle_attack_damage(cats: BattleCatsManager, self_cat: BattleCat, amount: int):
	@warning_ignore("integer_division") # Transfer amount should round down
	var transfer_amount = amount / 2
	if self_cat.is_shrouded:
		self_cat.is_shrouded = false
	else:
		self_cat.health -= amount - transfer_amount
	
	var back_cat = cats.get_back_adjacent_cat(self_cat)
	if back_cat != null:
		if back_cat.is_shrouded:
			back_cat.is_shrouded = false
		else:
			back_cat.health -= transfer_amount
	
