class_name EnchantmentStar
extends Enchantment

@export var stages: Array[StarStageStatusEffect] = []

func after_battle_start(_cats: BattleCatsManager, self_cat: BattleCat):
	_set_stage(self_cat, 0)

func after_battle_turn(_cats: BattleCatsManager, self_cat: BattleCat):
	if not stages.is_empty():
		var current: int = self_cat.ability_state.get(&"star_stage", 0)
		var next = mini(current + 1, stages.size() - 1)
		if next != current:
			_set_stage(self_cat, next)
			_cats.notify_ability_activated(self_cat)

func _set_stage(self_cat: BattleCat, index: int) -> void:
	if stages.is_empty():
		return
	var stage = stages[index]
	var old_attack: int = self_cat.ability_state.get(&"star_attack_bonus", 0)
	var old_health: int = self_cat.ability_state.get(&"star_health_bonus", 0)
	self_cat.ability_state[&"star_stage"] = index
	self_cat.ability_state[&"star_attack_bonus"] = stage.attack_bonus
	self_cat.ability_state[&"star_health_bonus"] = stage.health_bonus
	# Replace the previous phase's bonus while retaining damage and other buffs.
	self_cat.attack += stage.attack_bonus - old_attack
	if self_cat.health > 0:
		self_cat.health = maxi(1, self_cat.health + stage.health_bonus - old_health)
	var effects: Array[BattleStatusEffect] = [stage]
	self_cat.set_status_effect_grants(self, effects)

func on_battle_enchantment_removed(self_cat: BattleCat) -> void:
	self_cat.attack -= int(self_cat.ability_state.get(&"star_attack_bonus", 0))
	if self_cat.health > 0:
		self_cat.health = maxi(1, self_cat.health - int(self_cat.ability_state.get(&"star_health_bonus", 0)))
