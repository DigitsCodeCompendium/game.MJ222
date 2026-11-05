@abstract
class_name Enchantment
extends Resource

@export var display_name: String
@export var primary_color: Color
@export_multiline var description: String

@export var base_attack: int
@export var base_health: int

@export var income_offset: int

@export var cat_material: StandardMaterial3D
@export var cat_scene: PackedScene
## Optional expressions for this enchantment; null uses the cat's default set.
@export var face_set: CatFaceSet

@export var component1: Enchantment
@export var component2: Enchantment

## Always active on this Squeeb; removed effects are granted again immediately.
@export var innate_status_effects: Array[BattleStatusEffect] = []
## Granted to this Squeeb and its immediate teammates in the battle lineup.
@export var adjacent_status_effects: Array[BattleStatusEffect] = []

func has_components() -> bool:
	return component1 != null and component2 != null

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func before_attack(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func handle_attack_damage(_cats: BattleCatsManager, self_cat: BattleCat, amount: int, source: BattleCat = null):
	self_cat.take_damage(amount, source)

func after_attack(cats: BattleCatsManager, self_cat: BattleCat):
	pass

func after_normal_attack_received(_cats: BattleCatsManager, _self_cat: BattleCat) -> void:
	pass

func after_normal_attack_dealt(_cats: BattleCatsManager, _self_cat: BattleCat, _target: BattleCat, _damage: int) -> void:
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

func after_prep_start():
	pass

func refresh_battle_passives(_cats: BattleCatsManager, _self_cat: BattleCat) -> void:
	pass

func on_battle_enchantment_removed(_self_cat: BattleCat) -> void:
	pass

func after_ally_ability_activated(_cats: BattleCatsManager, _self_cat: BattleCat, _ally: BattleCat) -> void:
	pass

func after_dealing_damage(_cats: BattleCatsManager, _self_cat: BattleCat, _target: BattleCat, _amount: int) -> void:
	pass

func after_ally_damaged(_cats: BattleCatsManager, _self_cat: BattleCat, _ally: BattleCat, _amount: int) -> void:
	pass

func after_enemy_moved_by_ability(_cats: BattleCatsManager, _self_cat: BattleCat, _enemy: BattleCat) -> void:
	pass

func after_moved_by_ability(_cats: BattleCatsManager, _self_cat: BattleCat) -> void:
	pass

func after_movement_blocked(_cats: BattleCatsManager, _self_cat: BattleCat) -> void:
	pass

## Count occurrences, so Fire + Fire contains two Fire elements, not one.
func count_base_element(element: StringName) -> int:
	return _count_base_element(element, {})

func _count_base_element(element: StringName, ancestors: Dictionary) -> int:
	if ancestors.has(self):
		return 0
	var script_name = get_script().get_global_name()
	var basics = {&"fire": &"EnchantmentFire", &"water": &"EnchantmentWater", &"earth": &"EnchantmentEarth", &"air": &"EnchantmentAir"}
	if script_name == basics.get(element, &""):
		return 1
	var path = ancestors.duplicate()
	path[self] = true
	var count = 0
	for component in [component1, component2]:
		if component != null:
			count += component._count_base_element(element, path)
	return count
