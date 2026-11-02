class_name ShroudedStatusEffect
extends BattleStatusEffect

func blocks_damage(cat: BattleCat, _amount: int) -> bool:
	cat.remove_status_effect(status_id)
	return true
