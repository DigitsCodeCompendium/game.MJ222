class_name EnchantmentRecipe
extends Resource

@export var component1: Enchantment
@export var component2: Enchantment
@export var result: Enchantment
## If random_results is not empty, the script will use it instead of result
@export var random_results: Array[EnchantmentRecipeWeightedResult]

static func create(c1: Enchantment, c2: Enchantment, r: Enchantment):
	var recipe = EnchantmentRecipe.new()
	recipe.component1 = c1
	recipe.component2 = c2
	recipe.result = r
	return recipe

func _to_string():
	return "%s + %s = %s" % [component1.display_name, component2.display_name, str(random_results.size()) + " possible results" if (random_results != null and random_results.size() > 0) else result.display_name]

func get_result(rng: RandomNumberGenerator) -> Enchantment:
	if random_results != null and random_results.size() > 0:
		var weights = random_results.map(func (r): return r.weight)
		var index = rng.rand_weighted(PackedFloat32Array(weights))
		return random_results[index].result
	return result
