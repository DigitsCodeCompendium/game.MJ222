extends Node

@export var test_team_left: Array[CatData]
@export var test_team_right: Array[CatData]

func _ready():
	GameManager.is_test_env = true
	GameManager.test_team_left = test_team_left
	GameManager.test_team_right = test_team_right
	
func _process(delta):
	if Input.is_action_just_pressed("debug_click"):
		GameManager.start_battle()
