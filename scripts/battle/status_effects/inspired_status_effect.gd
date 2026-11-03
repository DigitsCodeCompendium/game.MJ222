class_name InspiredStatusEffect
extends BattleStatusEffect

func extra_normal_attacks(cat: BattleCat) -> int:
	return 0 if cat.has_made_normal_attack else 1

func after_normal_attack(cat: BattleCat) -> void:
	cat.remove_status_effect(status_id)
