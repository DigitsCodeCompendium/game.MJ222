class_name BattleCatsManager
extends Node3D

@export var battle_cat_scene: PackedScene

const team_size = 5

var cats_left: Array[BattleCat]
var cats_right: Array[BattleCat]

func _ready():
	cats_left = []
	cats_right = []

func load_cats():
	pass # TODO spawn in cats based on some kind of data being passed in somehow
