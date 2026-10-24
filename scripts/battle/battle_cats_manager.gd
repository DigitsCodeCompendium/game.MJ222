class_name BattleCatsManager
extends Node3D

@export var battle_cat_scene: PackedScene
@export var battle_cat_ui_scene: PackedScene

const team_size = 5

@export var left_cat_anchors: Array[Node3D]
@export var right_cat_anchors: Array[Node3D]

@export var move_duration = 0.5
@export var rotate_duration = 0.2

# Both arrays are the order of cats from front to back
var cats_left: Array[BattleCat]
var cats_right: Array[BattleCat]

func _ready():
	cats_left = []
	cats_right = []
	
	load_cats()

func load_cats():
	pass # TODO spawn in cats based on some kind of data being passed in somehow
	
	# TODO Placeholder cats for testing
	add_cat(cats_left, load("res://resources/enchantments/cat.tres"), 10, 10)
	add_cat(cats_left, load("res://resources/enchantments/air.tres"), 10, 10)
	add_cat(cats_left, load("res://resources/enchantments/water.tres"), 10, 10)
	add_cat(cats_right, load("res://resources/enchantments/cat.tres"), 10, 10)
	add_cat(cats_right, load("res://resources/enchantments/earth.tres"), 10, 10)
	add_cat(cats_right, load("res://resources/enchantments/fire.tres"), 10, 10)
	
	move_all_cats(true)
	
	for cat in cats_left:
		cat.enchantment.after_battle_start(self, cat)
	for cat in cats_right:
		cat.enchantment.after_battle_start(self, cat)

func _process(delta):
	if Input.is_action_just_pressed("debug_click"):
		do_turn()

func do_turn():
	for cat in cats_left:
		cat.enchantment.before_battle_turn(self, cat)
	for cat in cats_right:
		cat.enchantment.before_battle_turn(self, cat)
	
	check_for_deaths_and_move_all_cats()
	if is_battle_over():
		return
	
	deal_damage_to_cat(cats_left[0], cats_right[0], cats_left[0].attack)
	deal_damage_to_cat(cats_right[0], cats_left[0], cats_right[0].attack)
	
	check_for_deaths_and_move_all_cats()
	if is_battle_over():
		return

	for cat in cats_left:
		cat.enchantment.after_battle_turn(self, cat)
	for cat in cats_right:
		cat.enchantment.after_battle_turn(self, cat)
	
	check_for_deaths_and_move_all_cats()
	if is_battle_over():
		return

func add_cat(team: Array[BattleCat], enchantment: Enchantment, health: int, attack: int):
	var cat = battle_cat_scene.instantiate() as BattleCat
	cat.load_cat(enchantment, health, attack)
	
	team.append(cat)
	add_child(cat)
	
	var cat_ui = battle_cat_ui_scene.instantiate()
	cat_ui.camera = $"../Camera3D"
	cat_ui.attached_cat = cat
	cat.attached_ui = cat_ui
	cat_ui.update_cat()
	
	$"../CanvasLayer".add_child(cat_ui)

func move_all_cats(instant: bool = false):
	var tweens: Array[Tween] = []
	
	for i in range(cats_left.size()):
		tweens.append(move_cat(cats_left[i], left_cat_anchors[i], instant))
	
	for i in range(cats_right.size()):
		tweens.append(move_cat(cats_right[i], right_cat_anchors[i], instant))
	
	for tween in tweens:
		if tween != null:
			await tween.finished

func move_cat(cat: BattleCat, to: Node3D, instant: bool) -> Tween:
	if instant:
		cat.position = to.position
		cat.rotation = to.rotation
		return null
	else:
		var tween = create_tween()
		var move_dir = cat.position.direction_to(to.position)
		var move_rot = Basis.looking_at(-move_dir).get_euler() # Forward is -z so we need to flip look direction
		tween.tween_property(cat, "rotation", move_rot, rotate_duration)
		tween.tween_callback(cat.animate_move)
		tween.tween_property(cat, "position", to.position, move_duration)
		tween.tween_callback(cat.animate_idle)
		tween.tween_property(cat, "rotation", to.rotation, rotate_duration)
		return tween
	
func is_battle_over():
	return cats_left.size() <= 0 or cats_right.size() <= 0
	
func check_for_deaths_and_move_all_cats():
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
		for cat in dead_cats:
			cat.enchantment.before_battle_death(self, cat)
			cat.animate_death()
			cat.attached_ui.queue_free()
			cat.queue_free()
		move_all_cats()
		# Death effects may have killed more cats, check again
		check_for_deaths_and_move_all_cats()

func deal_damage_to_cat(source_cat: BattleCat, target_cat: BattleCat, amount: int, skip_hooks: bool = false):
	target_cat.health -= amount
	
	if skip_hooks:
		return
	
	for cat in cats_left:
		cat.enchantment.after_battle_damage(self, cat, source_cat, target_cat, amount)
	for cat in cats_right:
		cat.enchantment.after_battle_damage(self, cat, source_cat, target_cat, amount)
