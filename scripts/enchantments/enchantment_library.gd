extends Node

@export var all_enchantments: Array[Enchantment]
@export var additional_recipes: Array[EnchantmentRecipe]
@export var corrupted_enchantment: Enchantment

func combine_enchantments(e1: Enchantment, e2: Enchantment) -> Enchantment:
	for e in all_enchantments:
		if not e.has_components():
			continue
		if e.component1 == e1 and e.component2 == e2:
			return e
		if e.component1 == e2 and e.component2 == e1:
			return e
	
	for r in additional_recipes:
		if r.component1 == e1 and r.component2 == e2:
			return r.result
		if r.component1 == e2 and r.component2 == e1:
			return r.result
	
	return corrupted_enchantment
