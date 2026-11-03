class_name RingsStatusEffect
extends BattleStatusEffect

func modify_incoming_damage(_cat: BattleCat, amount: int) -> int:
	return maxi(0, amount - 2)
