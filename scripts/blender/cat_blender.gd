extends Area3D

@export var cat_manager: CatManager
@export var cat_scene: PackedScene
@export var cat_spawn_pos: Node3D

@export var corrupted_enchantment: Enchantment

var cat_enchantment1: Enchantment
var cat_enchantment2: Enchantment

func _ready():
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D):
	if body is Cat:
		print(body.cat_name + " the " + body.enchantment.display_name + " cat entered the blender")
		
		# Putting in a corrupted cat will give back a base cat
		if body.enchantment == corrupted_enchantment:
			# If the blender already consumed a cat, spit it back out
			if cat_enchantment1 != null:
				cat_manager.spawn_cat(cat_spawn_pos.global_position, cat_enchantment1)
			cat_manager.spawn_cat(cat_spawn_pos.global_position)
			
			cat_enchantment1 = null
			cat_enchantment2 = null
			body.queue_free()
			return
		
		if cat_enchantment1 == null:
			cat_enchantment1 = body.enchantment
			body.queue_free()
		elif cat_enchantment2 == null:
			cat_enchantment2 = body.enchantment
			body.queue_free()
		
		if cat_enchantment1 != null and cat_enchantment2 != null:
			var enchantment = EnchantmentLibrary.combine_enchantments(cat_enchantment1, cat_enchantment2)
			cat_manager.spawn_cat(cat_spawn_pos.global_position, enchantment)
			print("Created a " + enchantment.display_name + " cat")
			
			cat_enchantment1 = null
			cat_enchantment2 = null
