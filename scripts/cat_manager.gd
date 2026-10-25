extends Node3D
class_name CatManager

const CAT_SCENE = preload("res://scenes/cat/cat_test.tscn")

@export var possible_enchantments: Array[Enchantment]
@export var possible_names: Array[String] = ["Qwill", "Max", "Fish", "Spot"]

@export var cat_beds: Array[CatBed]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_cat(cat: Node):
	add_child(cat)

func spawn_cat(pos: Vector3, cat_data: CatData = null):
	var cat_instance = CAT_SCENE.instantiate() as Cat
	add_cat(cat_instance)
	cat_instance.global_position = pos
	
	if cat_data == null:
		cat_instance.cat_name = possible_names.pick_random()
		cat_instance.attack_offset = 0
		cat_instance.health_offset = 0
		cat_instance.set_enchantment(possible_enchantments.pick_random())
	else:
		cat_instance.cat_name = cat_data.cat_name
		cat_instance.attack_offset = cat_data.attack_offset
		cat_instance.health_offset = cat_data.health_offset
		cat_instance.set_enchantment(cat_data.enchantment)
