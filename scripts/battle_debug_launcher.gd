extends Node

@export var test_team_left: Array[CatData]
@export var test_team_right: Array[CatData]
@export var test_environment: PackedScene = preload("res://scenes/battle/environments/forest_environment.tscn")

var _launching: bool = false

func _ready() -> void:
	GameManager.is_test_env = true
	GameManager.test_team_left = test_team_left
	GameManager.test_team_right = test_team_right
	GameManager.test_environment = test_environment
	_start_battle()

func _start_battle() -> void:
	if _launching:
		return
	_launching = true
	_launch.call_deferred()

func _launch() -> void:
	GameManager.reset_game()
	GameManager.is_test_env = true
	GameManager.test_team_left = test_team_left
	GameManager.test_team_right = test_team_right
	GameManager.test_environment = test_environment
	GameManager.start_battle()
