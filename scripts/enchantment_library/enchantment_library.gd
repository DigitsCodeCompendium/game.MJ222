extends Node

@export var all_enchantments: Array[Enchantment]
@export var additional_recipes: Array[EnchantmentRecipe]
@export var corrupted_enchantment: Enchantment

var all_recipes: Array[EnchantmentRecipe]
var rng: RandomNumberGenerator

func _ready():
	all_recipes = []
	all_recipes.assign(
		all_enchantments\
			.filter(func (e): return e.has_components())\
			.map(func (e): return EnchantmentRecipe.create(e.component1, e.component2, e))
	)
	all_recipes.append_array(additional_recipes)
	
	print("There are %s enchantments and %s recipes in total" % [all_enchantments.size(), all_recipes.size()])
	
	# Warn if a combination has more than one resulting element to safeguard against mistakes
	for i in range(all_recipes.size()):
		for j in range(i+1, all_recipes.size()):
			var collision = false
			if all_recipes[i].component1 == all_recipes[j].component1 and all_recipes[i].component2 == all_recipes[j].component2:
				collision = true
			elif all_recipes[i].component1 == all_recipes[j].component2 and all_recipes[i].component2 == all_recipes[j].component1:
				collision = true
			if collision:
				printerr("Recipes `%s` (index %s) and `%s` (index %s) have the same components" % [all_recipes[i], i, all_recipes[j], j])
		
	rng = RandomNumberGenerator.new()

func combine_enchantments(e1: Enchantment, e2: Enchantment) -> Enchantment:
	for r in all_recipes:
		if r.component1 == e1 and r.component2 == e2:
			return r.get_result(rng)
		if r.component1 == e2 and r.component2 == e1:
			return r.get_result(rng)
	
	return corrupted_enchantment
