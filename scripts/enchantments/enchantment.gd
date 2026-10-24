@abstract
class_name Enchantment
extends Resource

@export var display_name: String
@export var primary_color: Color

@export var component1: Enchantment
@export var component2: Enchantment

func has_components() -> bool:
	return component1 != null and component2 != null
	
func on_battle_turn_begin(cats: BattleCatsManager, cat: BattleCat):
	pass

func on_battle_turn_end(cats: BattleCatsManager, cat: BattleCat):
	pass
