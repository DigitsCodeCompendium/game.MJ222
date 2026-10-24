class_name BattleCat
extends Node3D

var enchantment: Enchantment
var base_health: int
var base_attack: int
var health: int
var attack: int

var burn_stacks: int
var is_shrouded: bool

var attached_ui: Node

func load_cat(e: Enchantment, base_health: int, base_attack: int):
	enchantment = e
	self.base_health = base_health
	self.base_attack = base_attack
	health = base_health
	attack = base_attack
	
	burn_stacks = 0
	is_shrouded = false

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
