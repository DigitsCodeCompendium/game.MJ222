class_name ChilledStatusEffect
extends BattleStatusEffect

func modify_attack_damage(_cat: BattleCat, amount: int) -> int:
	# Never increase an attack that already deals zero damage.
	return maxi(1, amount - 1) if amount > 0 else amount

func after_battle_turn(cat: BattleCat) -> void:
	cat.consume_status_effect_stacks(status_id)
