class_name EnchantmentConcrete
extends Enchantment

@export var immovable_effect: BattleStatusEffect

func after_battle_turn(cats: BattleCatsManager, self_cat: BattleCat) -> void:
	if self_cat.health <= 0 or self_cat.ability_state.get(&"concrete_solid", false):
		return
	var remaining: int = self_cat.ability_state.get(&"concrete_turns_remaining", 3) - 1
	self_cat.ability_state[&"concrete_turns_remaining"] = remaining
	if remaining <= 0:
		self_cat.ability_state[&"concrete_solid"] = true
		self_cat.health += 4
		var effects: Array[BattleStatusEffect] = [immovable_effect]
		self_cat.set_status_effect_grants(self, effects)
		cats.notify_ability_activated(self_cat)

func after_moved_by_ability(_cats: BattleCatsManager, self_cat: BattleCat) -> void:
	if not self_cat.ability_state.get(&"concrete_solid", false):
		self_cat.ability_state[&"concrete_turns_remaining"] = self_cat.ability_state.get(&"concrete_turns_remaining", 3) + 1

func after_movement_blocked(cats: BattleCatsManager, self_cat: BattleCat) -> void:
	if not self_cat.ability_state.get(&"concrete_solid", false):
		return
	self_cat.attack += 2
	self_cat.health += 2
	cats.notify_ability_activated(self_cat)
