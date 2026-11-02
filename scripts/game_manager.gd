extends Node

signal money_changed(balance: int)
signal insufficient_funds(cost: int)
signal progress_changed

@export_range(0, 100, 1) var prep_income: int = 5


@export var enemy_starting_budget_modifier: int = -4
@export var enemy_budget_modifier_per_stage: int = 2
@export var player_initial_life: int = 9
## Five stages per run. Zero creates 2-3 random choices at that depth.
@export var stage_columns: Array[int] = [1, 0, 0, 0, 1]
@export var starting_stage: StageDefinition
@export var final_stage: StageDefinition
@export var stage_pool: Array[StageDefinition] = []
const RUN_ROUTE = preload("res://scripts/progression/run_route.gd")
var route = RUN_ROUTE.new()
var last_battle_stage: int = 1
var last_battle_level: int = 1
var total_rounds: int:
	get: return stage_columns.size() * RUN_ROUTE.LEVELS_PER_STAGE

const TEAM_SIZE = 5
const SCENE_FADE = preload("res://scenes/loading/scene_fade.tscn")
var _exiting_battle = false
var _starting_game = false
# Preserve the room theme across title, prep, and battle returns.
var room_theme: int = -1

const MAIN_MENU_SCENE = preload("res://scenes/title/title_screen.tscn")
const PREP_AREA_SCENE = preload("res://scenes/props/prep_area.tscn")
const BATTLE_ARENA_SCENE = preload("res://scenes/battle/battle_arena.tscn")
const TEST_BATTLE_SCENE = preload("res://scenes/debug/battle_debug_launcher.tscn")

# Current game state
var rng: RandomNumberGenerator
# Completed battles across the whole run (kept for existing battle callers).
var stage_index: int
var player_life: int
## All prep income granted this run, including enchantment income bonuses.
## Spending or leaving coins behind does not reduce the enemy's budget.
var player_total_coins_earned: int = 0
var player_money: int:
	set(value):
		player_money = maxi(0, value)
		money_changed.emit(player_money)
var _last_paid_prep_stage: int = -1
var enemy_seed: int
var enemy_team_cost: int
var enemy_extra_cost: int
# These two fields serve as a way to send cat team data to battle arena. They also preserve data for the prep area, for respawning cats when the player returns from battle.
var player_cats_team: Array[CatData]
var player_cats_reserve: Array[CatData]

# Derived information
var is_run_lost: bool:
	get: return player_life <= 0
var is_run_won: bool:
	get: return not is_run_lost and route.finished

# Temporary fields for transmitting information
var is_battle_won: bool

var is_test_env: bool = false
var test_team_left: Array[CatData]
var test_team_right: Array[CatData]
var test_environment: PackedScene

func _ready():
	reset_game()
	
func start_new_game(from_stairs: bool = false):
	if _starting_game:
		return
	_starting_game = true
	reset_game()
	var title = get_tree().current_scene
	if title != null and title.has_method("get_entrance_path") and title.get_entrance_path() != null:
		var entrance = load("res://scripts/title/game_entrance.gd").new()
		get_tree().root.add_child(entrance)
		await entrance.play(title, PREP_AREA_SCENE, from_stairs)
		entrance.queue_free()
		_starting_game = false
		return
	var transition = SCENE_FADE.instantiate()
	get_tree().root.add_child(transition)
	await transition.change_scene(PREP_AREA_SCENE)
	_starting_game = false

func reset_game():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	route.generate(rng, stage_columns, starting_stage, final_stage, stage_pool)
	last_battle_stage = 1
	last_battle_level = 1
	stage_index = 0
	player_life = player_initial_life
	player_total_coins_earned = 0
	player_money = 0
	_last_paid_prep_stage = -1
	enemy_seed = rng.randi()
	enemy_team_cost = 1
	enemy_extra_cost = 0
	player_cats_team = []
	player_cats_reserve = []
	progress_changed.emit()

func start_battle():
	if not is_test_env and (route.awaiting_choice or is_run_lost or is_run_won):
		return
	if not is_test_env and get_next_opponent_team().is_empty():
		push_warning("Cannot start battle: stage spawn rules have no affordable, priced enemies.")
		return
	get_tree().change_scene_to_packed(BATTLE_ARENA_SCENE)

func enter_prep() -> void:
	# Reloading the same prep round must not grant another payment.
	if _last_paid_prep_stage == stage_index:
		return
	_last_paid_prep_stage = stage_index
	
	var income = prep_income
	for cat_data in player_cats_team:
		income += cat_data.enchantment.income_offset
	income = maxi(0, income)
	player_total_coins_earned += income
	player_money = income
	
	_configure_enemy()

func _configure_enemy() -> void:
	enemy_seed = route.battle_seed()
	var modifier = enemy_starting_budget_modifier + int(route.current().get("depth", 0)) * enemy_budget_modifier_per_stage
	enemy_team_cost = maxi(1, player_total_coins_earned + modifier)
	var max_team_cost = TeamGenerator.get_max_possible_team_cost(TEAM_SIZE)
	if enemy_team_cost >= max_team_cost:
		enemy_extra_cost = enemy_team_cost - max_team_cost
		enemy_team_cost = max_team_cost
	else:
		enemy_extra_cost = 0

func can_afford(cost: int) -> bool:
	return cost >= 0 and player_money >= cost

func try_spend_coins(cost: int) -> bool:
	if not check_purchase_funds(cost):
		return false
	player_money -= cost
	return true

func check_purchase_funds(cost: int) -> bool:
	if can_afford(cost):
		return true
	if cost > player_money:
		insufficient_funds.emit(cost)
	return false

func get_loss_stakes() -> int:
	if route.is_final_level():
		return maxi(1, player_life)
	# Stage one is safe; later stages add one life lost per defeat.
	return maxi(0, int(route.current().get("depth", 0)))

func choose_next_stage(id: String) -> bool:
	if is_run_lost or is_run_won or not route.choose(id):
		return false
	_configure_enemy()
	progress_changed.emit()
	return true

func do_end_of_battle_calcs():
	if is_test_env or is_run_lost or is_run_won or route.awaiting_choice:
		return
	last_battle_stage = int(route.current().depth) + 1
	last_battle_level = route.level + 1
	if not is_battle_won:
		player_life = maxi(0, player_life - get_loss_stakes())
	stage_index += 1
	if not is_run_lost:
		route.complete_level()
	progress_changed.emit()

func exit_battle():
	if is_test_env:
		get_tree().change_scene_to_packed(TEST_BATTLE_SCENE)
		return

	if _exiting_battle:
		return
	_exiting_battle = true
	var destination = MAIN_MENU_SCENE if is_run_lost or is_run_won else PREP_AREA_SCENE
	var transition = SCENE_FADE.instantiate()
	get_tree().root.add_child(transition)
	await transition.change_scene(destination)
	_exiting_battle = false


func get_current_stage() -> StageDefinition:
	return route.current().get("definition") as StageDefinition

func get_next_opponent_team() -> Array[CatData]:
	if route.awaiting_choice or is_run_lost or is_run_won:
		return []
	var opponent_rng = RandomNumberGenerator.new()
	opponent_rng.seed = enemy_seed
	var progress = float(stage_index) / maxf(1.0, total_rounds - 1)
	var stage = get_current_stage()
	var rules = stage.spawn_rules if stage != null else null
	return TeamGenerator.generate_random_team(opponent_rng, TEAM_SIZE, enemy_team_cost, progress, enemy_extra_cost, rules)

func end_run() -> void:
	if _exiting_battle or _starting_game:
		return
	_exiting_battle = true
	is_test_env = false
	reset_game()
	var transition = SCENE_FADE.instantiate()
	get_tree().root.add_child(transition)
	await transition.change_scene(MAIN_MENU_SCENE)
	_exiting_battle = false
