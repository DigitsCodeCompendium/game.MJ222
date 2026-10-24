extends Node3D
class_name CatManager

const CAT_SCENE = preload("res://scenes/cat/cat_test.tscn")
@export var possible_enchantments: Array[Enchantment]
@export var possible_names: Array[String] = ["Qwill", "Max", "Fish", "Spot"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_cat(cat: Node):
	add_child(cat)

func spawn_cat(pos: Vector3, enchantment = null, name: String = ""):
	var cat_instance = CAT_SCENE.instantiate()
	add_cat(cat_instance)
	cat_instance.global_position = pos
	
	if enchantment == null:
		cat_instance.set_enchantment(possible_enchantments.pick_random())
	else:
		cat_instance.set_enchantment(enchantment)
	
	if name == "":
		cat_instance.name = possible_names.pick_random()
	else:
		cat_instance.name = name
