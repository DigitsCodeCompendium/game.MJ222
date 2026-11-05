class_name BattleCatsManager
extends Node3D

signal summon_tossed(enchantment: Enchantment)

@export var battle_cat_scene: PackedScene
@export var battle_cat_ui_scene: PackedScene

@export var left_cat_anchors: Array[Node3D]
@export var right_cat_anchors: Array[Node3D]

@export var move_duration = 0.5
@export var rotate_duration = 0.2

@export var direct_attack_hurt_delay = 0.5

@export var battle_end_countdown = 3

var turn_index: int = -1
var _lives_lost: int = 0
var _refreshing_passives = false
var _pending_summons: Array[Dictionary] = []
var _ability_events: Array[BattleCat] = []
var _ability_chain: Dictionary = {}
var _processing_abilities = false
var _ability_formation_changed = false
# Both arrays are the order of cats from front to back (inner to outer)
var cats_left: Array[BattleCat]
var cats_right: Array[BattleCat]

func _ready():
	AudioManager.play_battle_music()
	cats_left = []
	cats_right = []
	
	load_cats()
	%ResultContainer.visible = false
	# Resolve opening damage and summons before selecting the first attackers.
	await animate_attack_and_hurt()
	await check_for_deaths_and_move_all_cats()
	
	await get_tree().create_timer(1, false).timeout
	
	turn_index = 0
	while not is_battle_over():
		await do_turn()
		turn_index += 1
		# Yield even if a faulty ability returns early instead of animating.
		await get_tree().create_timer(0.0, false).timeout
	
	GameManager.is_battle_won = cats_left.size() > 0
	AudioManager.play_battle_result(GameManager.is_battle_won)
	var previous_lives = GameManager.player_life
	GameManager.do_end_of_battle_calcs()
	_lives_lost = maxi(0, previous_lives - GameManager.player_life)
	await animate_end_of_round_screen()
	GameManager.exit_battle()

func load_cats():
	if GameManager.is_test_env:
		load_cats_from_data(cats_left, GameManager.test_team_left)
		load_cats_from_data(cats_right, GameManager.test_team_right)
	else:
		load_cats_from_data(cats_left, GameManager.player_cats_team)
		
		var opponent_team = GameManager.get_next_opponent_team()
		load_cats_from_data(cats_right, opponent_team)
	
	move_all_cats(true)
	
	for cat in get_all_cats():
		cat.enchantment.after_battle_start(self, cat)
	sync_ui()
	move_all_cats(true)

func get_all_cats() -> Array[BattleCat]:
	return cats_left + cats_right

func do_turn():
	for cat in get_all_cats():
		cat.begin_battle_turn()
	print("Start turn %s: player team size %s, enemy team size %s" % [turn_index + 1, cats_left.size(), cats_right.size()])
	var original_attackers: Array[BattleCat] = [cats_left[0], cats_right[0]]
	var attack_counts: Array[int] = []
	for attacker in original_attackers:
		attack_counts.append(attacker.normal_attack_count())
	# Inspired is consumed on the first strike; cache the granted second strike.
	for strike in range(attack_counts.max()):
		if is_battle_over():
			break
		var attackers: Array[BattleCat] = []
		for i in original_attackers.size():
			if not is_instance_valid(original_attackers[i]):
				continue
			var attacker = original_attackers[i]
			if strike < attack_counts[i] and attacker in get_all_cats() and attacker.health > 0:
				attackers.append(attacker)
		if not attackers.is_empty():
			await _do_normal_attack_round(attackers)
	if not is_battle_over():
		var animations: Array[Promise] = []
		for cat in get_all_cats():
			animations.append(Promise.new(cat.enchantment.after_battle_turn.bind(self, cat)))
		await Promise.all(animations)
		sync_ui()
		await animate_attack_and_hurt()
		await check_for_deaths_and_move_all_cats()
	_finish_status_effect_turn()

func _do_normal_attack_round(attackers: Array[BattleCat]):
	var animations: Array[Promise] = []
	for attacker in attackers:
		animations.append(Promise.new(attacker.enchantment.before_attack.bind(self, attacker)))
	await Promise.all(animations)
	sync_ui()
	var targets: Array[BattleCat] = []
	# Opening attack abilities can faint enemies before the normal strike.
	await animate_attack_and_hurt()
	await check_for_deaths_and_move_all_cats()
	attackers = attackers.filter(func(cat): return is_instance_valid(cat) and cat in get_all_cats() and cat.health > 0)
	if attackers.is_empty() or is_battle_over():
		return
	var damages: Array[int] = []
	for attacker in attackers:
		var opponents = get_opposing_team(get_cat_team(attacker))
		if opponents.is_empty():
			return
		attacker.last_attack_target = opponents[0]
		targets.append(opponents[0])
		damages.append(attacker.get_attack_damage())
	# Both sides' damage is captured before either hit or status consumption.
	for i in attackers.size():
		targets[i].enchantment.handle_attack_damage(self, targets[i], damages[i], attackers[i])
	for attacker in attackers:
		attacker.finish_normal_attack()
		attacker.did_attack = true
	# React after both strikes resolve, so retreating cannot redirect either hit.
	for target in targets:
		if is_instance_valid(target) and target in get_all_cats() and target.health > 0:
			target.enchantment.after_normal_attack_received(self, target)
	sync_ui()
	await animate_attack_and_hurt(direct_attack_hurt_delay)
	var ally_snapshots: Array[Array] = []
	for attacker in attackers:
		var allies: Array[BattleCat] = []
		for ally in get_cat_team(attacker):
			if ally != attacker:
				allies.append(ally)
		ally_snapshots.append(allies)
	animations = []
	for attacker in attackers:
		animations.append(Promise.new(attacker.enchantment.after_attack.bind(self, attacker)))
	await Promise.all(animations)
	sync_ui()
	await animate_attack_and_hurt()
	await check_for_deaths_and_move_all_cats()
	if is_battle_over():
		return
	animations = []
	for allies in ally_snapshots:
		for ally in allies:
			if is_instance_valid(ally) and ally in get_all_cats():
				animations.append(Promise.new(ally.enchantment.after_ally_attack.bind(self, ally)))
	await Promise.all(animations)
	sync_ui()
	await animate_attack_and_hurt()
	await check_for_deaths_and_move_all_cats()

func _finish_status_effect_turn() -> void:
	for cat in get_all_cats():
		cat.finish_battle_turn()
	sync_ui()

func sync_ui():
	refresh_status_effect_auras()
	for cat in get_all_cats():
		if cat.attached_ui != null:
			cat.attached_ui.update_cat()

## Refresh lineup-dependent passives and combine overlapping status auras.
func refresh_status_effect_auras() -> void:
	if _refreshing_passives:
		return
	_refreshing_passives = true
	for cat in get_all_cats():
		if cat.enchantment != null:
			cat.enchantment.refresh_battle_passives(self, cat)
	for team in [cats_left, cats_right]:
		for i in team.size():
			var effects: Array[BattleStatusEffect] = []
			if team[i].health > 0:
				for j in range(maxi(0, i - 1), mini(team.size(), i + 2)):
					var source: BattleCat = team[j]
					if source.health > 0 and source.enchantment != null:
						effects.append_array(source.enchantment.adjacent_status_effects)
			team[i].set_status_effect_grants(self, effects)
	_refreshing_passives = false

func load_cats_from_data(team: Array[BattleCat], cats_data: Array[CatData]):
	for cat_data in cats_data:
		if cat_data == null or cat_data.enchantment == null:
			push_error("Cannot load a battle Squeeb without an enchantment.")
			continue
		var base_attack = cat_data.enchantment.base_attack + cat_data.attack_offset
		var base_health = cat_data.enchantment.base_health + cat_data.health_offset
		add_cat(team, cat_data.cat_name, cat_data.enchantment, base_attack, base_health)

func add_cat(team: Array[BattleCat], cat_name: String, enchantment: Enchantment, attack: int, health: int, index: int = -1):
	if enchantment == null:
		push_error("Cannot add a battle Squeeb without an enchantment.")
		return null
	if team.size() >= GameManager.TEAM_SIZE:
		return null
	var cat = battle_cat_scene.instantiate() as BattleCat
	cat.load_cat(cat_name, enchantment, attack, health)
	cat.battle_team = team
	cat.damage_received.connect(_on_damage_received.bind(cat))
	
	if index >= 0:
		team.insert(index, cat)
	else:
		team.append(cat)
	add_child(cat)
	cat.battle_traits_changed.connect(refresh_status_effect_auras)
	
	var cat_ui = battle_cat_ui_scene.instantiate()
	cat_ui.camera = $"../Camera3D"
	cat_ui.attached_cat = cat
	cat_ui.is_enemy = team == cats_right
	cat.attached_ui = cat_ui
	cat_ui.update_cat()
	
	%UI.add_child(cat_ui)
	refresh_status_effect_auras()
	
	return cat

func deal_ability_damage(source: BattleCat, target: BattleCat, amount: int) -> int:
	return target.take_damage(amount, source)

## Explicit displacements only; advancing the normal formation never calls this.
func notify_ability_movement(moved: BattleCat) -> void:
	if not is_instance_valid(moved) or not moved in get_all_cats() or moved.health <= 0:
		return
	var opponents = get_opposing_team(get_cat_team(moved)).duplicate()
	for observer in opponents:
		if is_instance_valid(observer) and observer in get_all_cats() and observer.health > 0:
			observer.enchantment.after_enemy_moved_by_ability(self, observer, moved)

func _on_damage_received(source: BattleCat, amount: int, target: BattleCat) -> void:
	for ally in get_cat_team(target).duplicate():
		if is_instance_valid(ally) and ally in get_all_cats() and ally.health > 0:
			ally.enchantment.after_ally_damaged(self, ally, target, amount)
	if is_instance_valid(source) and source.enchantment != null:
		source.enchantment.after_dealing_damage(self, source, target, amount)

## Change the lineup now; animate it after the current attack has finished.
func move_to_back_by_ability(cat: BattleCat) -> bool:
	var team = get_cat_team(cat)
	if team.size() < 2 or team.back() == cat or not cat.can_be_moved_in_battle():
		return false
	team.erase(cat)
	team.append(cat)
	_ability_formation_changed = true
	refresh_status_effect_auras()
	notify_ability_movement(cat)
	return true

## Each Squeeb can react once in a cascade, preventing Lightning feedback loops.
func notify_ability_activated(source: BattleCat) -> void:
	if not is_instance_valid(source):
		return
	var id = source.get_instance_id()
	if _processing_abilities:
		if not _ability_chain.has(id):
			_ability_chain[id] = true
			_ability_events.append(source)
		return
	_processing_abilities = true
	_ability_chain[id] = true
	_ability_events.append(source)
	while not _ability_events.is_empty():
		var activated: BattleCat = _ability_events.pop_front()
		for ally in activated.battle_team.duplicate():
			if is_instance_valid(ally) and ally != activated and ally.health > 0 and not _ability_chain.has(ally.get_instance_id()):
				ally.enchantment.after_ally_ability_activated(self, ally, activated)
	_ability_chain.clear()
	_processing_abilities = false

## Queue until fainted Squeebs leave the lineup, making their slots available.
func queue_summon(team: Array[BattleCat], cat_name: String, enchantment: Enchantment, attack: int, health: int, origin: Node3D, index: int = -1, before: BattleCat = null) -> void:
	if enchantment == null:
		push_error("Cannot summon a battle Squeeb without an enchantment.")
		return
	_pending_summons.append({
		"team": team, "cat_name": cat_name, "enchantment": enchantment,
		"attack": attack, "health": health, "position": origin.position,
		"rotation": origin.rotation, "index": index, "before": before,
		"left_team": is_same(team, cats_left),
	})

func _resolve_pending_summons() -> void:
	var requests = _pending_summons.duplicate()
	_pending_summons.clear()
	for request in requests:
		var team: Array[BattleCat] = request.team
		if team.size() >= GameManager.TEAM_SIZE:
			_toss_summon(request)
			continue
		var index: int = request.index
		if is_instance_valid(request.before) and request.before in team:
			index = team.find(request.before)
		if index >= 0:
			index = mini(index, team.size())
		var cat = add_cat(team, request.cat_name, request.enchantment, request.attack, request.health, index)
		if cat == null:
			continue
		cat.position = request.position
		cat.rotation = request.rotation

func _toss_summon(request: Dictionary) -> void:
	# A visual only: never gets a field slot, collision, UI, or battle abilities.
	var visual = preload("res://scenes/cat/cat_visual.tscn").instantiate() as CatVisual
	visual.name = "TossedSummon"
	visual.enchantment = request.enchantment
	add_child(visual)
	visual.position = request.position
	visual.rotation = request.rotation
	visual.play_loop("Idle")
	var side = -1.0 if request.left_team else 1.0
	var end = visual.position + Vector3(side * 4.5, -3.0, 2.0)
	var tween = visual.create_tween().set_parallel()
	tween.tween_method(_tween_toss.bind(visual, visual.position, end), 0.0, 1.0, 0.75)
	tween.tween_property(visual, "rotation:z", visual.rotation.z + side * TAU, 0.75)
	tween.tween_property(visual, "scale", Vector3.ONE * 0.05, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(visual.queue_free)
	summon_tossed.emit(request.enchantment)

func _tween_toss(t: float, visual: Node3D, start: Vector3, end: Vector3) -> void:
	visual.position = start.lerp(end, t) + Vector3.UP * sin(t * PI) * 3.0

func swallow_into_worm(source: BattleCat, victims: Array[BattleCat], worm: Enchantment) -> void:
	if worm == null:
		push_error("Dune requires a Worm enchantment before it can swallow Squeebs.")
		return
	var team = get_cat_team(source)
	if not source in team:
		return
	var attack = 0
	var health = 0
	var swallowed: Array[BattleCat] = []
	for victim in victims:
		if is_instance_valid(victim) and victim in get_all_cats() and not victim in swallowed:
			swallowed.append(victim)
			attack += maxi(0, victim.attack)
			health += maxi(0, victim.health)
	source.ability_state[&"swallowed_by_worm"] = true
	for victim in swallowed:
		if victim == source:
			continue
		get_cat_team(victim).erase(victim)
		var no_effects: Array[BattleStatusEffect] = []
		victim.set_status_effect_grants(self, no_effects)
		_animate_swallowed(victim, source.position)
	queue_summon(team, "Shai", worm, attack, health, source, team.find(source))
	var emerging = preload("res://scenes/cat/cat_visual.tscn").instantiate() as CatVisual
	emerging.enchantment = worm
	emerging.name = "EmergingWorm"
	add_child(emerging)
	emerging.position = source.position + Vector3.DOWN * 1.2
	emerging.rotation = source.rotation
	emerging.play_loop("Attack")
	var tween = emerging.create_tween()
	tween.tween_property(emerging, "position:y", source.position.y, 0.2)
	tween.tween_interval(0.3)
	tween.tween_callback(emerging.queue_free)
	refresh_status_effect_auras()
	notify_ability_activated(source)

func _animate_swallowed(cat: BattleCat, center: Vector3):
	if cat.attached_ui != null:
		cat.attached_ui.hide()
	if cat.is_class("CollisionObject3D"):
		cat.set("input_ray_pickable", false)
	var tween = cat.create_tween().set_parallel()
	tween.tween_property(cat, "position", center + Vector3.DOWN * 0.8, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(cat, "scale", Vector3.ONE * 0.01, 0.45)
	await tween.finished
	if is_instance_valid(cat.attached_ui):
		cat.attached_ui.queue_free()
	cat.queue_free()

func animate_attack_and_hurt(hurt_delay: float = 0):
	var animations: Array[Promise] = []
	
	for cat in get_all_cats():
		if cat.did_attack:
			cat.did_attack = false
			cat.was_damaged = false
			animations.append(Promise.new(cat.animate_attack))
		elif cat.was_damaged:
			cat.was_damaged = false
			animations.append(Promise.new(animate_hurt_cat_with_delay.bind(cat, hurt_delay)))
	
	await Promise.all(animations)

func animate_hurt_cat_with_delay(cat: BattleCat, delay: float):
	await get_tree().create_timer(delay, false).timeout
	await cat.animate_hurt()

func move_all_cats(instant: bool = false):
	var animations: Array[Promise] = []
	for i in range(cats_left.size()):
		animations.append(Promise.new(move_cat.bind(cats_left[i], left_cat_anchors[i], instant)))
	for i in range(cats_right.size()):
		animations.append(Promise.new(move_cat.bind(cats_right[i], right_cat_anchors[i], instant)))
	await Promise.all(animations)

func move_cat(cat: BattleCat, to: Node3D, instant: bool):
	if instant:
		cat.position = to.position
		cat.rotation = to.rotation
		return null
	else:
		var tween = create_tween()
		
		var move_dist = cat.position.distance_squared_to(to.position)
		if not is_zero_approx(move_dist):
			var move_look_dir = cat.position.direction_to(to.position)
			
			move_look_dir.y = 0
			if not is_zero_approx(move_look_dir.length_squared()):
				var move_rot = Basis.looking_at(move_look_dir).get_euler()
				tween.tween_property(cat, "rotation", move_rot, rotate_duration)
			
			tween.tween_callback(cat.animate_move)
			tween.tween_property(cat, "position", to.position, move_duration)
			tween.tween_callback(cat.animate_idle)
		
		tween.tween_property(cat, "rotation", to.rotation, rotate_duration)
		if tween.is_running():
			await tween.finished
	
func is_battle_over():
	return cats_left.size() <= 0 or cats_right.size() <= 0
	
func check_for_deaths_and_move_all_cats():
	var dead_cats: Array[BattleCat] = []
	var no_effects: Array[BattleStatusEffect] = []
	
	for team in [cats_left, cats_right]:
		var i = 0
		while i < team.size():
			var dying: BattleCat = team[i]
			if dying.health > 0:
				i += 1
				continue
			dying.enchantment.before_death(self, dying)
			# Swallowing can remove neighbours and shift the dying Squeeb's index.
			var death_index: int = team.find(dying)
			if death_index < 0:
				continue
			if dying.health > 0:
				sync_ui()
				i = death_index + 1
				continue
			for ally in team.duplicate():
				if ally != dying and ally in team:
					ally.enchantment.before_ally_death(self, ally, dying)
			dead_cats.append(dying)
			team.erase(dying)
			dying.set_status_effect_grants(self, no_effects)
			refresh_status_effect_auras()
			i = mini(i, death_index)

	if not dead_cats.is_empty() or not _pending_summons.is_empty():
		var death_animations: Array[Promise] = []
		for cat in dead_cats:
			cat.enchantment.after_death(self, cat)
			death_animations.append(Promise.new(animate_death_and_despawn.bind(cat)))
		await Promise.all(death_animations)
		_resolve_pending_summons()
		sync_ui()
		
		# Death effects may have killed more cats, check again
		await animate_attack_and_hurt()
		await move_all_cats()
		await check_for_deaths_and_move_all_cats()
	if _ability_formation_changed:
		_ability_formation_changed = false
		await move_all_cats()

func animate_death_and_despawn(cat: BattleCat):
	if cat.ability_state.get(&"swallowed_by_worm", false):
		await _animate_swallowed(cat, cat.position)
		return
	await cat.animate_death()
	cat.attached_ui.queue_free()
	cat.queue_free()

func animate_end_of_round_screen():
	var run_finished = GameManager.is_run_lost or GameManager.is_run_won
	var title: String
	var accent: Color
	if GameManager.is_run_lost:
		title = "Run over"
		accent = Color("ee8a82")
	elif GameManager.is_run_won:
		title = "Run won!"
		accent = Color("efd17c")
	elif cats_left.is_empty() and cats_right.is_empty():
		title = "Draw"
		accent = Color("a6bddf")
	elif cats_right.is_empty():
		title = "Victory!"
		accent = Color("88d6a4")
	else:
		title = "Defeat"
		accent = Color("ee8a82")
	%ResultContainer.present(title, accent, GameManager.stage_index, GameManager.player_life, run_finished, _lives_lost)
	if run_finished:
		await wait_for_player_continue()
	else:
		await do_continue_countdown()

func wait_for_player_continue():
	%ReturnTimerLabel.visible = false
	%SkipLabel.visible = false
	%ContinueButton.visible = true
	await %ContinueButton.pressed

func do_continue_countdown():
	var tween = create_tween()
	var set_timer_text = func(t): %ReturnTimerLabel.text = "Returning to prep in %s..." % t
	set_timer_text.call(battle_end_countdown)
	for i in range(battle_end_countdown, 0, -1):
		tween.tween_callback(set_timer_text.bind(i))
		tween.tween_interval(1)
	
	%ReturnTimerLabel.visible = true
	%SkipLabel.visible = true
	%ContinueButton.visible = false
	
	var handle_gui_input = func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			tween.pause()
			tween.custom_step(battle_end_countdown)
	%ResultContainer.gui_input.connect(handle_gui_input)
	
	await tween.finished
	%ResultContainer.gui_input.disconnect(handle_gui_input)

func get_cat_team(cat: BattleCat) -> Array[BattleCat]:
	if cat in cats_left:
		return cats_left
	elif cat in cats_right:
		return cats_right
	else:
		return []

func get_opposing_team(team: Array[BattleCat]) -> Array[BattleCat]:
	if team == cats_left:
		return cats_right
	elif team == cats_right:
		return cats_left
	else:
		return []
	
func get_front_adjacent_cat(cat: BattleCat) -> BattleCat:
	var i = cats_left.find(cat)
	if i >= 0:
		if i > 0:
			return cats_left[i-1]
		elif cats_right.size() > 0:
			return cats_right[0]
		else:
			return null
	
	i = cats_right.find(cat)
	if i >= 0:
		if i > 0:
			return cats_right[i-1]
		elif cats_left.size() > 0:
			return cats_left[0]
		else:
			return null
	
	return null

func get_back_adjacent_cat(cat: BattleCat) -> BattleCat:
	var i = cats_left.find(cat)
	if i >= 0:
		if i + 1 < cats_left.size():
			return cats_left[i+1]
		else:
			return null
	
	i = cats_right.find(cat)
	if i >= 0:
		if i + 1 < cats_right.size():
			return cats_right[i+1]
		else:
			return null
	
	return null
