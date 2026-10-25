class_name BattleCatsManager
extends Node3D

@export var battle_cat_scene: PackedScene
@export var battle_cat_ui_scene: PackedScene

@export var left_cat_anchors: Array[Node3D]
@export var right_cat_anchors: Array[Node3D]

@export var move_duration = 0.5
@export var rotate_duration = 0.2

var turn_index: int
# Both arrays are the order of cats from front to back (inner to outer)
var cats_left: Array[BattleCat]
var cats_right: Array[BattleCat]

func _ready():
	cats_left = []
	cats_right = []
	
	load_cats()
	
	turn_index = 0
	while not is_battle_over():
		await do_turn()
		turn_index += 1
	
	if cats_left.size() <= 0:
		if cats_right.size() <= 0:
			%ResultLabel.text = "Tie"
		else:
			%ResultLabel.text = "Defeat"
		GameManager.is_battle_won = false
	elif cats_right.size() <= 0:
		%ResultLabel.text = "Victory"
		GameManager.is_battle_won = true
	%ResultContainer.visible = true
	
	GameManager.do_end_of_battle_calcs()
	
	await get_tree().create_timer(5).timeout
	
	GameManager.exit_battle()

func load_cats():
	if GameManager.is_test_env:
		load_cats_from_data(cats_left, GameManager.test_team_left)
		load_cats_from_data(cats_right, GameManager.test_team_right)
	else:
		load_cats_from_data(cats_left, GameManager.player_cats_team)
		
		var rng = RandomNumberGenerator.new()
		rng.seed = GameManager.enemy_seed
		var game_progress = float(GameManager.stage_index) / (GameManager.total_rounds - 1)
		var opponent_team = TeamGenerator.generate_random_team(rng, GameManager.TEAM_SIZE, GameManager.enemy_team_cost, game_progress, GameManager.enemy_extra_cost)
		load_cats_from_data(cats_right, opponent_team)
	
	move_all_cats(true)
	
	for cat in get_all_cats():
		cat.enchantment.after_battle_start(self, cat)
	sync_ui()

func get_all_cats() -> Array[BattleCat]:
	return cats_left + cats_right

func do_turn():
	print("Start turn %s: player team size %s, enemy team size %s" % [turn_index + 1, cats_left.size(), cats_right.size()])
	await Promise.all([
		Promise.new(cats_left[0].enchantment.before_attack.bind(self, cats_left[0])),
		Promise.new(cats_right[0].enchantment.before_attack.bind(self, cats_right[0]))
	])
	sync_ui()
	
	cats_right[0].enchantment.handle_attack_damage(self, cats_right[0], cats_left[0].attack)
	cats_left[0].enchantment.handle_attack_damage(self, cats_left[0], cats_right[0].attack)
	cats_left[0].did_attack = true
	cats_right[0].did_attack = true
	sync_ui()
	
	await play_attack_and_hurt_animations()
	
	# Save a snapshot of which cats should get the "ally attacked" event, because the cats order may change
	var ally_cats_left = cats_left.slice(1)
	var ally_cats_right = cats_right.slice(1)
	
	await Promise.all([
		Promise.new(cats_left[0].enchantment.after_attack.bind(self, cats_left[0])),
		Promise.new(cats_right[0].enchantment.after_attack.bind(self, cats_right[0]))
	])
	sync_ui()
	
	await play_attack_and_hurt_animations()
	await check_for_deaths_and_move_all_cats()
	if is_battle_over():
		return
	
	var animations: Array[Promise] = []
	for cat in ally_cats_left:
		if cat in cats_left:
			animations.append(Promise.new(cat.enchantment.after_ally_attack.bind(self, cat)))
	for cat in ally_cats_right:
		if cat in cats_right:
			animations.append(Promise.new(cat.enchantment.after_ally_attack.bind(self, cat)))
	await Promise.all(animations)
	sync_ui()
	
	await play_attack_and_hurt_animations()
	await check_for_deaths_and_move_all_cats()
	if is_battle_over():
		return

	animations = []
	for cat in get_all_cats():
		animations.append(Promise.new(cat.enchantment.after_battle_turn.bind(self, cat)))
	await Promise.all(animations)
	sync_ui()
	
	await play_attack_and_hurt_animations()
	await check_for_deaths_and_move_all_cats()
	if is_battle_over():
		return

func sync_ui():
	for cat in get_all_cats():
		if cat.attached_ui != null:
			cat.attached_ui.update_cat()

func load_cats_from_data(team: Array[BattleCat], cats_data: Array[CatData]):
	for cat_data in cats_data:
		var base_attack = cat_data.enchantment.base_attack + cat_data.attack_offset
		var base_health = cat_data.enchantment.base_health + cat_data.health_offset
		add_cat(team, cat_data.cat_name, cat_data.enchantment, base_attack, base_health)

func add_cat(team: Array[BattleCat], cat_name: String, enchantment: Enchantment, attack: int, health: int, index: int = -1):
	var cat = battle_cat_scene.instantiate() as BattleCat
	cat.load_cat(cat_name, enchantment, attack, health)
	
	if index >= 0:
		team.insert(index, cat)
	else:
		team.append(cat)
	add_child(cat)
	
	var cat_ui = battle_cat_ui_scene.instantiate()
	cat_ui.camera = $"../Camera3D"
	cat_ui.attached_cat = cat
	cat.attached_ui = cat_ui
	cat_ui.update_cat()
	
	%UI.add_child(cat_ui)
	
	return cat

func play_attack_and_hurt_animations():	
	var animations: Array[Promise] = []
	
	for cat in get_all_cats():
		if cat.did_attack:
			cat.did_attack = false
			cat.was_damaged = false
			animations.append(Promise.new(cat.animate_attack))
		elif cat.was_damaged:
			cat.was_damaged = false
			animations.append(Promise.new(cat.animate_hurt))
	
	await Promise.all(animations)

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
	
	var i = 0
	while i < cats_left.size():
		if cats_left[i].health <= 0:
			cats_left[i].enchantment.before_death(self, cats_left[i])
			for ally_cat in cats_left:
				if ally_cat != cats_left[i]:
					ally_cat.enchantment.before_ally_death(self, ally_cat, cats_left[i])
			dead_cats.append(cats_left[i])
			cats_left.remove_at(i)
		else:
			i += 1
	i = 0
	while i < cats_right.size():
		if cats_right[i].health <= 0:
			cats_right[i].enchantment.before_death(self, cats_right[i])
			for ally_cat in cats_right:
				if ally_cat != cats_right[i]:
					ally_cat.enchantment.before_ally_death(self, ally_cat, cats_right[i])
			dead_cats.append(cats_right[i])
			cats_right.remove_at(i)
		else:
			i += 1
	
	if dead_cats.size() > 0:
		var death_animations: Array[Promise] = []
		for cat in dead_cats:
			cat.enchantment.after_death(self, cat)
			death_animations.append(Promise.new(animate_death_and_despawn.bind(cat)))
		await Promise.all(death_animations)
		await move_all_cats()
		# Death effects may have killed more cats, check again
		await check_for_deaths_and_move_all_cats()

func animate_death_and_despawn(cat: BattleCat):
	await cat.animate_death()
	cat.attached_ui.queue_free()
	cat.queue_free()

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
