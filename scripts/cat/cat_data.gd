class_name CatData
extends Resource

var cat_name: String
var attack_offset: int
var health_offset: int
var enchantment: Enchantment

func _to_string():
	return "%s (%s +%s/+%s)" % [cat_name, enchantment.display_name, attack_offset, health_offset]
