class_name StageSpawnRules
extends Resource

## An empty list allows no enemies. A missing rules resource uses the normal pool.
@export var allowed_enchantments: Array[Enchantment] = []

func allows(enchantment: Enchantment) -> bool:
	return enchantment != null and enchantment in allowed_enchantments
