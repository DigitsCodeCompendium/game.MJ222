@abstract
class_name Enchantment
extends Resource

@export var display_name: String
@export var primary_color: Color
@export_multiline var description: String

@export var component1: Enchantment
@export var component2: Enchantment

func has_components() -> bool:
	return component1 != null and component2 != null

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func before_attack(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func handle_attack_damage(cats: BattleCatsManager, self_cat: BattleCat, amount: int):
	self_cat.health -= amount

func after_attack(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func before_death(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func after_death(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func after_battle_turn(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func can_be_moved_in_battle() -> bool:
	return true
