class_name EnchantmentSteam
extends Enchantment

func handle_attack_damage(cats: BattleCatsManager, self_cat: BattleCat, amount: int):
	@warning_ignore("integer_division") # Transfer amount should round down
	var transfer_amount = amount / 2
	self_cat.take_damage(amount - transfer_amount)
	
	var back_cat = cats.get_back_adjacent_cat(self_cat)
	if back_cat != null:
		back_cat.take_damage(transfer_amount)
	
