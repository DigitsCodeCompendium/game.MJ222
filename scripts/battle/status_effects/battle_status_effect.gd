## Shared definition only. Active effects and their visuals belong to each BattleCat.
class_name BattleStatusEffect
extends Resource

@export var status_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var visual_scene: PackedScene
@export var stackable: bool = false

## Return true to prevent this hit. Effects may remove themselves when consumed.
func blocks_damage(_cat: BattleCat, _amount: int) -> bool:
	return false

func modify_incoming_damage(_cat: BattleCat, amount: int) -> int:
	return amount

func extra_normal_attacks(_cat: BattleCat) -> int:
	return 0

## Override in an effect script to control forced movement by abilities.
func allows_forced_movement(_cat: BattleCat) -> bool:
	return true

func modify_attack_damage(_cat: BattleCat, amount: int) -> int:
	return amount

func after_normal_attack(_cat: BattleCat) -> void:
	pass

func after_battle_turn(_cat: BattleCat) -> void:
	pass
