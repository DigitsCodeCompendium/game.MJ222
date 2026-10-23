class_name EnchantmentRecipe
extends Resource

@export var component1: Enchantment
@export var component2: Enchantment
@export var result: Enchantment

func _to_string():
	return "%s + %s = %s" % [component1.display_name, component2.display_name, result.display_name]
