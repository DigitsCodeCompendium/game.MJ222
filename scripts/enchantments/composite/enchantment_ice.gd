class_name EnchantmentIce
extends Enchantment

@export var enchantment_ice_statue: Enchantment

func before_death(cats: BattleCatsManager, self_cat: BattleCat):
	var team = cats.get_cat_team(self_cat)
	var health = ceili(self_cat.base_health / 2.0)
	var attack = ceili(self_cat.base_attack / 2.0)
	var i = team.find(self_cat)
	var statue = cats.add_cat(team, "Ice Statue", enchantment_ice_statue, health, attack, i + 1) # Cat manager will delete the cat at index i next, so put the statue one index down
	statue.position = self_cat.position + Vector3(0, 4, 0)
	statue.rotation = self_cat.rotation
