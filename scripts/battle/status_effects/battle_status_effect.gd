## Shared definition only. Active effects and their visuals belong to each BattleCat.
class_name BattleStatusEffect
extends Resource

@export var status_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var visual_scene: PackedScene

## Return true to prevent this hit. Effects may remove themselves when consumed.
func blocks_damage(_cat: BattleCat, _amount: int) -> bool:
	return false

## Override in an effect script to control forced movement by abilities.
func allows_forced_movement(_cat: BattleCat) -> bool:
	return true

func modify_attack_damage(_cat: BattleCat, amount: int) -> int:
	return amount

func after_normal_attack(_cat: BattleCat) -> void:
	pass
