class_name BattleCat
extends Node3D

var _enchantment: Enchantment
var enchantment: Enchantment:
	get: return _enchantment

var base_health: int
var base_attack: int
var health: int
var attack: int

var shroud_ability_used: bool
var is_shrouded: bool

var attached_ui: Node

const DEFAULT_CAT_MAT = preload("res://assets/cat/elements/default_cat.tres")

func load_cat(e: Enchantment, base_health: int, base_attack: int):
	_enchantment = e
	self.base_health = base_health
	self.base_attack = base_attack
	health = base_health
	attack = base_attack
	
	shroud_ability_used = false
	is_shrouded = false

func set_enchantment(e: Enchantment):
	_enchantment = e
	
	if not is_node_ready():
		return
	
	if enchantment != null and enchantment.cat_material != null:
		set_body_material(enchantment.cat_material)
	else:
		# Duplicate so tinting one cat never changes another cat's material.
		var material = DEFAULT_CAT_MAT.duplicate() as StandardMaterial3D
		if enchantment != null:
			material.albedo_color = enchantment.primary_color
		set_body_material(material)

func set_body_material(mat: StandardMaterial3D):
	$Cat/Armature/Skeleton3D/Cat.set_surface_override_material(0, mat)

func animate_idle():
	pass # TODO

func animate_move():
	pass # TODO

func animate_attack():
	pass # TODO

func animate_hurt():
	pass # TODO

func animate_death():
	pass # TODO
