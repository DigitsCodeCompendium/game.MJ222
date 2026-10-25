class_name BattleCat
extends Node3D

var _enchantment: Enchantment
var enchantment: Enchantment:
	get: return _enchantment

var cat_name: String
var base_attack: int
var base_health: int
var attack: int
var health: int

var shroud_ability_used: bool
var is_shrouded: bool

var did_attack: bool
var was_damaged: bool

var attached_ui: Node

@onready var visual: CatVisual = $CatVisual

func _ready() -> void:
	visual.set_enchantment(enchantment)
	animate_idle()

@warning_ignore("shadowed_variable")
func load_cat(n: String, e: Enchantment, base_attack: int, base_health: int):
	cat_name = n
	set_enchantment(e)
	self.base_attack = base_attack
	self.base_health = base_health
	attack = base_attack
	health = base_health
	
	shroud_ability_used = false
	is_shrouded = false
	did_attack = false
	was_damaged = false

func set_enchantment(e: Enchantment) -> void:
	_enchantment = e
	if is_node_ready():
		visual.set_enchantment(e)

func take_damage(amount: int):
	if is_shrouded:
		is_shrouded = false
	else:
		health -= amount
		was_damaged = true

func animate_idle() -> void:
	visual.play_loop("Idle")

func animate_move() -> void:
	visual.play_loop("Walk")

func animate_attack() -> void:
	await visual.play_once("Attack")
	animate_idle()

func animate_hurt() -> void:
	await visual.play_once("Pancake")
	animate_idle()

func animate_death() -> void:
	await visual.play_once("Death")
