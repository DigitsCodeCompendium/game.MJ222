class_name EnchantmentStatic
extends Enchantment

func after_moved_by_ability(cats: BattleCatsManager, self_cat: BattleCat) -> void:
	if self_cat.health <= 0:
		return
	var enemies = cats.get_opposing_team(cats.get_cat_team(self_cat)).filter(func(cat): return cat.health > 0)
	if enemies.is_empty():
		return
	var target = enemies[GameManager.rng.randi_range(0, enemies.size() - 1)]
	cats.deal_ability_damage(self_cat, target, 3)
	cats.notify_ability_activated(self_cat)
