class_name BattleCat
extends Node3D

signal status_effects_changed
signal battle_traits_changed

var _enchantment: Enchantment
var enchantment: Enchantment:
	get: return _enchantment

var cat_name: String
var base_attack: int
var base_health: int
var attack: int
var health: int:
	set(value):
		if health == value:
			return
		health = value
		battle_traits_changed.emit()

var shroud_ability_used: bool
var preservation_used: bool
var normal_attack_bonus: int
var _status_effects: Array[BattleStatusEffect] = []
var _status_stacks: Dictionary[StringName, int] = {}
var _turn_start_status_stacks: Dictionary[StringName, int] = {}
var _status_visuals: Dictionary[StringName, Node3D] = {}
var _direct_status_effects: Dictionary[StringName, BattleStatusEffect] = {}
# Keys are the enchantment (innate effects) or battle manager (combined ally auras).
var _status_effect_grants: Dictionary = {}

var did_attack: bool
var was_damaged: bool
var last_attack_target: BattleCat

var attached_ui: Node

@onready var visual: CatVisual = $CatVisual

func _ready() -> void:
	visual.set_enchantment(enchantment)
	for effect in _status_effects:
		_create_status_visual(effect)
	animate_idle()

@warning_ignore("shadowed_variable")
func load_cat(n: String, e: Enchantment, base_attack: int, base_health: int):
	cat_name = n
	_status_effect_grants.clear()
	clear_status_effects()
	set_enchantment(e)
	self.base_attack = base_attack
	self.base_health = base_health
	attack = base_attack
	health = base_health
	
	shroud_ability_used = false
	preservation_used = false
	normal_attack_bonus = 0
	did_attack = false
	was_damaged = false
	last_attack_target = null

func set_enchantment(e: Enchantment) -> void:
	if _enchantment != null:
		_status_effect_grants.erase(_enchantment)
	_enchantment = e
	if e != null:
		_status_effect_grants[e] = e.innate_status_effects
	_refresh_granted_status_effects()
	if is_node_ready():
		visual.set_enchantment(e)
	battle_traits_changed.emit()

func get_attack_damage() -> int:
	var amount = attack + normal_attack_bonus
	for effect in _status_effects:
		amount = effect.modify_attack_damage(self, amount)
	return amount

func finish_normal_attack() -> void:
	for effect in _status_effects.duplicate():
		if has_status_effect(effect.status_id):
			effect.after_normal_attack(self)
	normal_attack_bonus = 0

func begin_battle_turn() -> void:
	_turn_start_status_stacks = _status_stacks.duplicate()

func finish_battle_turn() -> void:
	# Freshly applied stacks get a chance to affect the following turn.
	for effect in _status_effects.duplicate():
		if _turn_start_status_stacks.get(effect.status_id, 0) > 0:
			effect.after_battle_turn(self)
	_turn_start_status_stacks.clear()

func take_damage(amount: int):
	# A consumed effect can remove itself while processing this hit.
	for effect in _status_effects.duplicate():
		if has_status_effect(effect.status_id) and effect.blocks_damage(self, amount):
			return
	health -= amount
	was_damaged = true

## Formation movement still works; this only governs forced movement by abilities.
func can_be_moved_in_battle() -> bool:
	for effect in _status_effects:
		if not effect.allows_forced_movement(self):
			return false
	return true

func has_status_effect(status_id: StringName) -> bool:
	for effect in _status_effects:
		if effect.status_id == status_id:
			return true
	return false

## Only effects explicitly marked stackable can accumulate more than one stack.
func add_status_effect(effect: BattleStatusEffect, stacks: int = 1) -> bool:
	if effect == null or effect.status_id.is_empty() or stacks <= 0:
		return false
	if has_status_effect(effect.status_id):
		if not effect.stackable:
			return false
		_status_stacks[effect.status_id] += stacks
		status_effects_changed.emit()
		return true
	_direct_status_effects[effect.status_id] = effect
	_activate_status_effect(effect, stacks if effect.stackable else 1)
	return true

func get_status_effect_stacks(status_id: StringName) -> int:
	return _status_stacks.get(status_id, 0)

## Returns how many stacks were consumed; consuming the last removes the effect.
func consume_status_effect_stacks(status_id: StringName, amount: int = 1) -> int:
	var consumed = mini(get_status_effect_stacks(status_id), maxi(0, amount))
	if consumed == 0:
		return 0
	_status_stacks[status_id] -= consumed
	if _turn_start_status_stacks.has(status_id):
		_turn_start_status_stacks[status_id] = maxi(0, _turn_start_status_stacks[status_id] - consumed)
	if _status_stacks[status_id] == 0:
		remove_status_effect(status_id)
	else:
		status_effects_changed.emit()
	return consumed

func _activate_status_effect(effect: BattleStatusEffect, stacks: int = 1) -> void:
	_status_effects.append(effect)
	_status_stacks[effect.status_id] = stacks
	if is_node_ready():
		_create_status_visual(effect)
	status_effects_changed.emit()

func remove_status_effect(status_id: StringName) -> void:
	_direct_status_effects.erase(status_id)
	_deactivate_status_effect(status_id)
	_refresh_granted_status_effects()

func _deactivate_status_effect(status_id: StringName) -> void:
	for effect in _status_effects:
		if effect.status_id != status_id:
			continue
		_status_effects.erase(effect)
		_status_stacks.erase(status_id)
		_turn_start_status_stacks.erase(status_id)
		var effect_visual = get_status_visual(status_id)
		if effect_visual != null:
			effect_visual.hide()
			effect_visual.queue_free()
		_status_visuals.erase(status_id)
		status_effects_changed.emit()
		return

func clear_status_effects() -> void:
	_direct_status_effects.clear()
	for effect in _status_effects.duplicate():
		_deactivate_status_effect(effect.status_id)
	_refresh_granted_status_effects()

## Replace one source's grants, preserving effects granted by other sources.
func set_status_effect_grants(source: Object, effects: Array[BattleStatusEffect]) -> void:
	if effects.is_empty():
		_status_effect_grants.erase(source)
	else:
		_status_effect_grants[source] = effects.duplicate()
	_refresh_granted_status_effects()

func _refresh_granted_status_effects() -> void:
	var desired = _direct_status_effects.duplicate()
	for effects in _status_effect_grants.values():
		for effect in effects:
			if effect != null and not effect.status_id.is_empty():
				desired[effect.status_id] = effect
	for effect in _status_effects.duplicate():
		if not desired.has(effect.status_id):
			_deactivate_status_effect(effect.status_id)
	for effect in desired.values():
		if not has_status_effect(effect.status_id):
			_activate_status_effect(effect)

func get_status_effects() -> Array[BattleStatusEffect]:
	return _status_effects.duplicate()

func get_status_visual(status_id: StringName) -> Node3D:
	return _status_visuals.get(status_id)

func _create_status_visual(effect: BattleStatusEffect) -> void:
	if effect.visual_scene == null:
		return
	var instance = effect.visual_scene.instantiate()
	if not instance is Node3D:
		push_error("Status effect visual_scene must have a Node3D root.")
		instance.free()
		return
	add_child(instance)
	_status_visuals[effect.status_id] = instance

func animate_idle() -> void:
	visual.play_loop("Idle")

func animate_move() -> void:
	visual.play_loop("Walk")

func animate_attack() -> void:
	AudioManager.play_effect("attack")
	await visual.play_once("Attack")
	animate_idle()

func animate_hurt() -> void:
	AudioManager.play_effect("hurt")
	await visual.play_once("Pancake")
	animate_idle()

func animate_death() -> void:
	AudioManager.play_effect("death")
	await visual.play_once("Death")
