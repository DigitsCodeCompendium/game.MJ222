class_name RingsStatusEffect
extends BattleStatusEffect

func modify_incoming_damage(cat: BattleCat, amount: int) -> int:
	return maxi(1, amount - cat.get_status_effect_stacks(status_id)) if amount > 0 else amount
