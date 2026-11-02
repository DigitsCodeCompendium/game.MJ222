class_name ChilledStatusEffect
extends BattleStatusEffect

func modify_attack_damage(_cat: BattleCat, amount: int) -> int:
	# Never increase an attack that already deals zero damage.
	return maxi(1, amount - 1) if amount > 0 else amount

func after_normal_attack(cat: BattleCat) -> void:
	cat.remove_status_effect(status_id)
