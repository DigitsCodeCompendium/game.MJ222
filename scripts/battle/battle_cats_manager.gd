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

func do_turn():
	for cat in cats_left:
		cat.enchantment.on_battle_turn_begin(self, cat)
	for cat in cats_right:
		cat.enchantment.on_battle_turn_begin(self, cat)
	
	check_for_deaths_and_move_cats()
	if is_battle_over():
		return
	
	# TODO cats damage each other

	for cat in cats_left:
		cat.enchantment.on_battle_turn_end(self, cat)
	for cat in cats_right:
		cat.enchantment.on_battle_turn_end(self, cat)
	
	check_for_deaths_and_move_cats()
	if is_battle_over():
		return
	
func is_battle_over():
	return cats_left.size() > 0 and cats_right.size() > 0
	
func check_for_deaths_and_move_cats():
	var dead_cats: Array[BattleCat] = []
	
	var i = 0
	while i < cats_left.size():
		if cats_left[i].health <= 0:
			dead_cats.append(cats_left[i])
			cats_left.remove_at(i)
		else:
			i += 1
	i = 0
	while i < cats_right.size():
		if cats_right[i].health <= 0:
			dead_cats.append(cats_right[i])
			cats_right.remove_at(i)
		else:
			i += 1
	
	if dead_cats.size() > 0:
		pass
		# TODO fire death hooks
		# TODO animate cats moving to new positions
