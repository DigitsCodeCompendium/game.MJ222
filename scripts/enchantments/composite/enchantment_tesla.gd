class_name EnchantmentTesla
extends Enchantment

func after_normal_attack_dealt(cats: BattleCatsManager, self_cat: BattleCat, target: BattleCat, damage: int) -> void:
	var opponents = cats.get_opposing_team(cats.get_cat_team(self_cat))
	var index = opponents.find(target)
	if index < 0 or damage <= 0:
		return
	var adjacent: Array[BattleCat] = []
	for i in [index - 1, index + 1]:
		if i >= 0 and i < opponents.size() and opponents[i].health > 0:
			adjacent.append(opponents[i])
	if adjacent.is_empty() or GameManager.rng.randf() >= 0.5:
		return
	var bounced_target = adjacent[GameManager.rng.randi_range(0, adjacent.size() - 1)]
	# Ability damage cannot trigger another normal-attack bounce.
	cats.deal_ability_damage(self_cat, bounced_target, damage)
	cats.notify_ability_activated(self_cat)
