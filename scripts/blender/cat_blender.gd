extends Area3D

@export var cats_parent: Node3D
@export var cat_scene: PackedScene

var cat_enchantment1: Enchantment
var cat_enchantment2: Enchantment

func _ready():
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D):
	if body is Cat:
		print(body.cat_name + " the " + body.enchantment.display_name + " cat entered the blender")
		
		if cat_enchantment1 == null:
			cat_enchantment1 = body.enchantment
			body.queue_free()
		elif cat_enchantment2 == null:
			cat_enchantment2 = body.enchantment
			body.queue_free()
		
		if cat_enchantment1 != null and cat_enchantment2 != null:
			var new_cat = cat_scene.instantiate()
			new_cat.enchantment = EnchantmentLibrary.combine_enchantments(cat_enchantment1, cat_enchantment2)
			cats_parent.add_child(new_cat)
			print("Created a " + new_cat.enchantment.display_name + " cat")
			
			cat_enchantment1 = null
			cat_enchantment2 = null
