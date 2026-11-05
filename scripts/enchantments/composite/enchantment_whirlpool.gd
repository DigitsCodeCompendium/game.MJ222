class_name EnchantmentWhirlpool
extends Enchantment

@export var shrouded_effect: BattleStatusEffect

func after_ally_damaged(cats: BattleCatsManager, self_cat: BattleCat, ally: BattleCat, amount: int) -> void:
	if self_cat.ability_state.get(&"whirlpool_rescued", false):
		return
	var team = cats.get_cat_team(self_cat)
	if team.size() < 2 or team.front() != ally or ally.health <= 0 or ally.base_health <= 0:
		return
	# Only a surviving hit that crosses the halfway point can trigger a rescue.
	if ally.health * 2 >= ally.base_health or (ally.health + amount) * 2 < ally.base_health:
		return
	if not cats.can_move_by_ability(ally):
		return
	# Commit before movement notifications, which can cause further ability damage.
	self_cat.ability_state[&"whirlpool_rescued"] = true
	ally.add_status_effect(shrouded_effect)
	cats.move_to_back_by_ability(ally)
	cats.notify_ability_activated(self_cat)
