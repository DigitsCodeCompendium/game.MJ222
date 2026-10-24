class_name BattleCat
extends Node3D

var enchantment: Enchantment
var health: int
var attack: int

func load_cat(e: Enchantment, base_health: int, base_attack: int):
	enchantment = e
	health = base_health
	attack = base_attack

func animate_idle():
	pass # TODO

func animate_move():
	pass # TODO

func animate_attack():
	pass # TODO
