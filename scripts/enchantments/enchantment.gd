@abstract
class_name Enchantment
extends Resource

@export var display_name: String
@export var primary_color: Color

@export var component1: Enchantment
@export var component2: Enchantment

func has_components() -> bool:
	return component1 != null and component2 != null
	
@abstract func on_battle_turn(cats: BattleCatsManager, cat: BattleCat)
