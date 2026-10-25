@abstract
class_name Enchantment
extends Resource

@export var display_name: String
@export var primary_color: Color
@export_multiline var description: String

@export var attack_modifier: int
@export var health_modifier: int

@export var cat_material: StandardMaterial3D

@export var component1: Enchantment
@export var component2: Enchantment

func has_components() -> bool:
	return component1 != null and component2 != null

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	self_cat.base_attack += attack_modifier
	self_cat.attack += attack_modifier
	self_cat.base_health += health_modifier
	self_cat.health += health_modifier

func before_attack(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func handle_attack_damage(cats: BattleCatsManager, self_cat: BattleCat, amount: int):
	if self_cat.is_shrouded:
		self_cat.is_shrouded = false
	else:
		self_cat.health -= amount

func after_attack(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func after_ally_attack(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func before_death(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func before_ally_death(cats: BattleCatsManager, self_cat: BattleCat, ally_cat: BattleCat):
	pass

func after_death(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func after_battle_turn(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func can_be_moved_in_battle() -> bool:
	return true
