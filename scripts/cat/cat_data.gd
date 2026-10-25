class_name CatData
extends Resource

@export var cat_name: String
@export var attack_offset: int
@export var health_offset: int
@export var enchantment: Enchantment

func _to_string():
	return "%s (%s +%s/+%s)" % [cat_name, enchantment.display_name, attack_offset, health_offset]
