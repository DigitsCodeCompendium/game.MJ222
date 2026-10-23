extends Node

@export var all_enchantments: Array[Enchantment]
@export var additional_recipes: Array[EnchantmentRecipe]
@export var corrupted_enchantment: Enchantment

func _ready():
	# Warn if a combination has more than one resulting element to safeguard against mistakes
	for i in range(all_enchantments.size()):
		if not all_enchantments[i].has_components():
			continue
		for j in range(i+1, all_enchantments.size()):
			if not all_enchantments[j].has_components():
				continue
			var collision = false
			if all_enchantments[i].component1 == all_enchantments[j].component1 and all_enchantments[i].component2 == all_enchantments[j].component2:
				collision = true
			elif all_enchantments[i].component1 == all_enchantments[j].component2 and all_enchantments[i].component2 == all_enchantments[j].component1:
				collision = true
			if collision:
				printerr("Enchantments " + all_enchantments[i].display_name + " and " + all_enchantments[j].display_name + " have the same components")
				
		for j in range(additional_recipes.size()):
			var collision = false
			if all_enchantments[i].component1 == additional_recipes[j].component1 and all_enchantments[i].component2 == additional_recipes[j].component2:
				collision = true
			elif all_enchantments[i].component1 == additional_recipes[j].component2 and all_enchantments[i].component2 == additional_recipes[j].component1:
				collision = true
			if collision:
				printerr("Enchantment %s and recipe `%s` (index %s) have the same components" % [all_enchantments[i].display_name, additional_recipes[j], j])
	for i in range(additional_recipes.size()):
		for j in range(i+1, additional_recipes.size()):
			var collision = false
			if additional_recipes[i].component1 == additional_recipes[j].component1 and additional_recipes[i].component2 == additional_recipes[j].component2:
				collision = true
			elif additional_recipes[i].component1 == additional_recipes[j].component2 and additional_recipes[i].component2 == additional_recipes[j].component1:
				collision = true
			if collision:
				printerr("Recipes `%s` (index %s) and `%s` (index %s) have the same components" % [additional_recipes[i], i, additional_recipes[j], j])

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
