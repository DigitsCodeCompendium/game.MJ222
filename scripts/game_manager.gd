extends Node

@export var enemy_cost_base: float = 1.45
@export var total_rounds: int = 10
@export var min_wins_required: int = 7

const TEAM_SIZE = 5

const PREP_AREA_SCENE = preload("res://scenes/prep_area.tscn")
const BATTLE_ARENA_SCENE = preload("res://scenes/battle/battle_arena.tscn")

# Current game state
var rng: RandomNumberGenerator
var stage_index: int
var current_wins: int
var player_money: int
var enemy_seed: int
var enemy_team_cost: int
var enemy_extra_cost: int
# These two fields serve as a way to send cat team data to battle arena. They also preserve data for the prep area, for respawning cats when the player returns from battle.
var player_cats_team: Array[CatData]
var player_cats_reserve: Array[CatData]

# Temporary fields for transmitting information
var is_battle_won: bool

func _ready():
	reset_game()

func reset_game():
	rng = RandomNumberGenerator.new()
	stage_index = 0
	current_wins = 0
	player_money = 1
	enemy_seed = rng.randi()
	enemy_team_cost = 1
	enemy_extra_cost = 0
	player_cats_team = []
	player_cats_reserve = []

func start_battle():
	get_tree().change_scene_to_packed(BATTLE_ARENA_SCENE)

func finish_battle():
	stage_index += 1
	if is_battle_won:
		current_wins += 1
	player_money += stage_index
	enemy_seed = rng.randi()
	enemy_team_cost = roundi(pow(enemy_cost_base, stage_index))
	var max_team_cost = TeamGenerator.get_max_possible_team_cost(5)
	if enemy_team_cost >= max_team_cost:
		enemy_extra_cost = enemy_team_cost - max_team_cost
		enemy_team_cost = max_team_cost
	else:
		enemy_extra_cost = 0
	
	get_tree().change_scene_to_packed(PREP_AREA_SCENE)
