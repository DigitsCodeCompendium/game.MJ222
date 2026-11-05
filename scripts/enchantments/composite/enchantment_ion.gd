class_name EnchantmentIon
extends Enchantment

func after_ally_attack(cats: BattleCatsManager, self_cat: BattleCat) -> void:
	if self_cat.health <= 0:
		return
	var team = cats.get_cat_team(self_cat)
	var index = team.find(self_cat)
	# The frontmost Ion has no ally in front; never target the opposing team.
	if index <= 0:
		return
	var ally = team[index - 1]
	if ally.health <= 0:
		return
	ally.attack += 3
	ally.health -= 1
	cats.notify_ability_activated(self_cat)
