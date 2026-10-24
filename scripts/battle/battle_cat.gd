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
