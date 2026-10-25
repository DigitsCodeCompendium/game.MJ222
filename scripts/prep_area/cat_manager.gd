extends Node3D
class_name CatManager

const CAT_SCENE = preload("res://scenes/cat/prep_cat.tscn")

@export var start_battle_door: PrepAreaDoor
@export var battle_transition: CanvasLayer
@export var departure_speed: float = 6.0
@export_range(1.0, 5.0, 0.1) var departure_catchup_multiplier: float = 2.5
@export_range(1.0, 5.0, 0.1) var departure_final_boost: float = 2.0
@export var nav_region: NavigationRegion3D

@export var possible_enchantments: Array[Enchantment]
@export var possible_names: Array[String] = ["Qwill", "Max", "Fish", "Spot"]
## Maximum number of active prep cats. Cats queued for deletion free their slot immediately.
@export_range(0, 100, 1) var cat_limit: int = 10
@export var cat_beds: Array[CatBed]
@export var constrain_cat_drag: bool = false
@export var cat_drag_bounds: Rect2 = Rect2(-14.7, -14.7, 29.4, 29.4)

var _starting_battle = false
var _departing_cats: Array[Cat] = []
var _remaining_departures = 0

var used_names: Array[String]:
	get:
		var names: Array[String] = []
		for cat in get_cats():
			names.append(cat.cat_name)
		return names

func _ready() -> void:
	GameManager.enter_prep()
	# Need to give nav server a frame to load, otherwise can't find random position in a nav mesh for spawning cats distributedly
	await NavigationServer3D.map_changed
	load_cats_from_game_state()
	update_start_game_button()

func get_cats() -> Array[Cat]:
	var cats: Array[Cat] = []
	for child in get_children():
		if child is Cat and not child.is_queued_for_deletion():
			cats.append(child)
	return cats

func get_cat_count() -> int:
	return get_cats().size()

func can_spawn_cat(amount: int = 1) -> bool:
	return not _starting_battle and get_cat_count() + amount <= cat_limit

func get_unique_name(preferred: String = "") -> String:
	var taken: Array[String] = []
	for existing in used_names:
		taken.append(existing.strip_edges().to_lower())
	preferred = preferred.strip_edges()
	if not preferred.is_empty() and not taken.has(preferred.to_lower()):
		return preferred
	var available: Array[String] = []
	for candidate in possible_names:
		candidate = candidate.strip_edges()
		if not candidate.is_empty() and not taken.has(candidate.to_lower()) and not available.has(candidate):
			available.append(candidate)
	if not available.is_empty():
		return available.pick_random()
	# A short name list should not prevent filling otherwise available cat slots.
	var base = preferred if not preferred.is_empty() else "Squeeb"
	if preferred.is_empty():
		for candidate in possible_names:
			if not candidate.strip_edges().is_empty():
				base = candidate.strip_edges()
				break
	var suffix = 2
	var result = base
	while taken.has(result.to_lower()):
		result = "%s %d" % [base, suffix]
		suffix += 1
	return result

func add_cat(cat: Cat) -> bool:
	if not can_spawn_cat() or cat.get_parent() != null:
		return false
	cat.cat_name = get_unique_name(cat.cat_name)
	if constrain_cat_drag:
		cat.constrain_drag_to_room = true
		cat.drag_bounds = cat_drag_bounds
	add_child(cat)
	return true

func remove_cat(cat: Cat) -> void:
	if is_instance_valid(cat) and cat.get_parent() == self:
		cat.queue_free()

func get_held_cat() -> Cat:
	for child in get_children():
		if child is Cat and child.is_picked and not child.is_queued_for_deletion():
			return child
	return null

func get_hovered_bed_cat(camera: Camera3D, mouse_position: Vector2) -> Cat:
	if camera == null:
		return null
	var origin = camera.project_ray_origin(mouse_position)
	var end = origin + camera.project_ray_normal(mouse_position) * camera.far
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	var cat = hit.get("collider") as Cat
	if cat == null or cat.get_parent() != self or cat.is_queued_for_deletion() or cat._is_dropping:
		return null
	for bed in get_tree().get_nodes_in_group("cat_beds"):
		if is_instance_valid(bed) and bed.placed_cat == cat:
			return cat
	return null

## Charges only for a successfully purchased cat.
func buy_cat(at: Variant = null) -> Cat:
	if not can_spawn_cat() or not GameManager.can_afford(GameManager.CAT_PRICE):
		return null
	var cat = spawn_cat(find_random_cat_spawn_pos() if at == null else at)
	if cat != null:
		GameManager.try_spend_coins(GameManager.CAT_PRICE)
	return cat

## Free spawning is used when restoring saved cats and producing merge results.
func spawn_cat(pos: Vector3, cat_data: CatData = null) -> Cat:
	if not can_spawn_cat():
		return null
	var selected_enchantment: Enchantment
	if cat_data != null:
		selected_enchantment = cat_data.enchantment
	else:
		var valid = possible_enchantments.filter(func(e): return e != null)
		if valid.is_empty():
			return null
		selected_enchantment = valid.pick_random()
	var cat_instance = CAT_SCENE.instantiate() as Cat
	cat_instance.cat_name = get_unique_name(cat_data.cat_name if cat_data != null else "")
	cat_instance.attack_offset = cat_data.attack_offset if cat_data != null else 0
	cat_instance.health_offset = cat_data.health_offset if cat_data != null else 0
	cat_instance.set_enchantment(selected_enchantment)
	# Set the local position before _ready so the cat starts at the requested world point.
	cat_instance.position = to_local(pos)
	if not add_cat(cat_instance):
		cat_instance.free()
		return null
	return cat_instance

func find_random_cat_spawn_pos() -> Vector3:
	return NavigationServer3D.region_get_random_point(nav_region.get_rid(), 1, false)

func load_cats_from_game_state():
	for i in range(GameManager.player_cats_team.size()):
		var cat = spawn_cat(cat_beds[i].global_position, GameManager.player_cats_team[i])
		cat_beds[i].try_place_cat(cat)
	
	for cat in GameManager.player_cats_reserve:
		var pos = find_random_cat_spawn_pos()
		spawn_cat(pos, cat)

func _on_cat_placed(cat: Node3D):
	update_start_game_button()

func update_start_game_button():
	if _starting_battle:
		return
	for bed in cat_beds:
		if is_instance_valid(bed.placed_cat):
			if start_battle_door.disabled:
				start_battle_door.reset_coin_warning()
			start_battle_door.disabled = false
			return
	start_battle_door.disabled = true

func _on_door_clicked():
	if _starting_battle:
		return
	var team_cats: Array[Node3D] = [] # Used later for checking which cats are in reserve
	var team: Array[CatData] = [] # Data passed to game manager and battle arena
	for bed in cat_beds:
		if is_instance_valid(bed.placed_cat):
			team_cats.append(bed.placed_cat)
			team.append(bed.placed_cat.get_cat_data())
	if team.is_empty():
		start_battle_door.show_missing_team()
		for bed in cat_beds:
			bed.flash_empty()
		return
	if get_held_cat() != null:
		return
	if not start_battle_door.confirm_remaining_coins(GameManager.player_money):
		return
	_starting_battle = true
	start_battle_door.disabled = true
	GameManager.player_cats_team = team
	
	var reserve: Array[CatData] = []
	for cat in get_cats():
		if not cat in team_cats:
			reserve.append(cat.get_cat_data())
	GameManager.player_cats_reserve = reserve
	
	battle_transition.block_input()
	# Stop bed locks and player interaction before moving the team.
	for bed in get_tree().get_nodes_in_group("cat_beds"):
		bed.set_physics_process(false)
		bed._release_cat()
	for cat in get_cats():
		cat.set_physics_process(false)
		cat.set_process_input(false)
		cat.input_ray_pickable = false
		cat.navigation_agent.avoidance_enabled = false
		cat.velocity = Vector3.ZERO
	await start_battle_door.open_door()
	await _animate_team_departure(team_cats)
	battle_transition.go_to_battle()

func _process(_delta: float) -> void:
	for cat in _departing_cats:
		if is_instance_valid(cat):
			cat._sync_state_animation()

func _animate_team_departure(team_cats: Array[Node3D]) -> void:
	var door_position = start_battle_door.global_position
	# A shared aisle keeps the cats away from the other team beds.
	var aisle_z = door_position.z + 7.5
	team_cats.sort_custom(func(a, b): return a.global_position.distance_to(door_position) < b.global_position.distance_to(door_position))
	_remaining_departures = team_cats.size()
	var departure_tweens: Array[Tween] = []
	for i in team_cats.size():
		var cat = team_cats[i] as Cat
		_departing_cats.append(cat)
		cat._enter_behavior(Cat.State.IDLE)
		var tween = create_tween()
		departure_tweens.append(tween)
		if i > 0:
			tween.tween_interval(i * 0.55)
		tween.tween_callback(cat._enter_behavior.bind(Cat.State.WANDERING))
		var at = cat.global_position
		var waypoints: Array[Vector3] = [
			Vector3(at.x, 0.1, aisle_z),
			Vector3(door_position.x, 0.1, aisle_z),
			Vector3(door_position.x, 0.1, door_position.z - 2.5)]
		for target in waypoints:
			var direction = target - at
			if Vector2(direction.x, direction.z).length() < 0.01:
				continue
			var yaw = atan2(-direction.x, -direction.z)
			tween.tween_method(func(weight): cat.global_rotation.y = lerp_angle(cat.global_rotation.y, yaw, weight), 0.0, 1.0, 0.15)
			tween.tween_property(cat, "global_position", target, at.distance_to(target) / maxf(departure_speed, 0.1))
			at = target
		tween.tween_callback(cat.hide)
		tween.tween_callback(func():
			var exited = team_cats.size() - _remaining_departures + 1
			if exited == 1 or exited == 3:
				var speed = departure_catchup_multiplier
				if exited == 3:
					speed *= departure_final_boost
				# Boost once after the first exit, then again after the third.
				for departure in departure_tweens:
					if departure.is_valid():
						departure.set_speed_scale(speed)
				for remaining_cat in _departing_cats:
					if remaining_cat.visible and remaining_cat.visual.animation_player != null:
						remaining_cat.visual.animation_player.speed_scale = speed
			_remaining_departures -= 1)
	while _remaining_departures > 0:
		await get_tree().process_frame
	_departing_cats.clear()
