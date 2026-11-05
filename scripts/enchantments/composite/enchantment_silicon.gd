class_name EnchantmentSilicon
extends Enchantment

func handle_ability_damage(cats: BattleCatsManager, self_cat: BattleCat, amount: int, _source: BattleCat = null) -> int:
	if amount > 0 and self_cat.health > 0:
		# Convert the hit before damage-only defenses, preserving Shrouded.
		self_cat.health += amount
		cats.notify_ability_activated(self_cat)
	return 0
