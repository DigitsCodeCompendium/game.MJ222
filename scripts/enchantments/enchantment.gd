@abstract
class_name Enchantment
extends Resource

@export var display_name: String
@export var primary_color: Color

@export var component1: Enchantment
@export var component2: Enchantment

func has_components() -> bool:
	return component1 != null and component2 != null

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func before_battle_turn(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func after_battle_damage(cats: BattleCatsManager, self_cat: BattleCat, source_cat: BattleCat, target_cat: BattleCat, amount: int):
	pass

func before_battle_death(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func after_battle_turn(cats: BattleCatsManager, self_cat: BattleCat):
	pass
