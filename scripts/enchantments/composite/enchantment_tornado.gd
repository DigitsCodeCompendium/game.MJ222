class_name EnchantmentTornado
extends Enchantment

func after_enemy_moved_by_ability(cats: BattleCatsManager, self_cat: BattleCat, enemy: BattleCat) -> void:
	if enemy.health <= 0:
		return
	cats.deal_ability_damage(self_cat, enemy, 2)
	cats.notify_ability_activated(self_cat)
