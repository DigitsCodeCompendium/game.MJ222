extends Node

@export var difficulty_base: float = 1.45

const PREP_AREA_SCENE = preload("res://scenes/prep_area.tscn")
const BATTLE_ARENA_SCENE = preload("res://scenes/battle/battle_arena.tscn")

# Current game state
var rng: RandomNumberGenerator
var stage_index: int
var player_money: int
var enemy_seed: int
# These two fields also serve as ways to preserve data for the prep area, when the player goes to battle scene and back.
var player_cats_team: Array[CatData]
var player_cats_reserve: Array[CatData]

func _ready():
	pass

func reset_game():
	rng = RandomNumberGenerator.new()
	stage_index = 0
	player_money = 1
	enemy_seed = rng.randi()

func load_prep_area():
	get_tree().change_scene_to_packed(PREP_AREA_SCENE)

func load_battle_arena():
	get_tree().change_scene_to_packed(BATTLE_ARENA_SCENE)
