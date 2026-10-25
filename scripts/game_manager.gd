extends Node

signal money_changed(balance: int)

@export_range(0, 100, 1) var prep_income: int = 5

const CAT_PRICE = 1
const MERGE_PRICE = 2

@export var enemy_cost_base: float = 1.45
@export var total_rounds: int = 10
@export var player_initial_life: int = 3

const TEAM_SIZE = 5

const MAIN_MENU_SCENE = preload("res://scenes/title/title_screen.tscn")
const PREP_AREA_SCENE = preload("res://scenes/prep_area.tscn")
const BATTLE_ARENA_SCENE = preload("res://scenes/battle/battle_arena.tscn")
const TEST_BATTLE_SCENE = preload("res://scenes/battle_test.tscn")

# Current game state
var rng: RandomNumberGenerator
var stage_index: int
var player_life: int
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

# Temporary fields for transmitting information
var is_battle_won: bool

var is_test_env: bool = false
var test_team_left: Array[CatData]
var test_team_right: Array[CatData]

func _ready():
	reset_game()
	
func start_new_game():
	reset_game()
	get_tree().change_scene_to_packed(PREP_AREA_SCENE)

func reset_game():
	rng = RandomNumberGenerator.new()
	stage_index = 0
	player_life = player_initial_life
	player_money = 0
	_last_paid_prep_stage = -1
	enemy_seed = rng.randi()
	enemy_team_cost = 1
	enemy_extra_cost = 0
	player_cats_team = []
	player_cats_reserve = []

func start_battle():
	get_tree().change_scene_to_packed(BATTLE_ARENA_SCENE)

func enter_prep() -> void:
	# Reloading the same prep round must not grant another payment.
	if _last_paid_prep_stage == stage_index:
		return
	_last_paid_prep_stage = stage_index
	player_money += prep_income
	
	enemy_seed = rng.randi()
	enemy_team_cost = roundi(pow(enemy_cost_base, stage_index))
	var max_team_cost = TeamGenerator.get_max_possible_team_cost(5)
	if enemy_team_cost >= max_team_cost:
		enemy_extra_cost = enemy_team_cost - max_team_cost
		enemy_team_cost = max_team_cost
	else:
		enemy_extra_cost = 0

func can_afford(cost: int) -> bool:
	return cost >= 0 and player_money >= cost

func try_spend_coins(cost: int) -> bool:
	if not can_afford(cost):
		return false
	player_money -= cost
	return true

func finish_battle():
	if is_test_env:
		get_tree().change_scene_to_packed(TEST_BATTLE_SCENE)
		return
	
	stage_index += 1
	if not is_battle_won:
		player_life -= 1
	
	if player_life <= 0:
		get_tree().change_scene_to_packed(MAIN_MENU_SCENE)
	else:
		get_tree().change_scene_to_packed(PREP_AREA_SCENE)
