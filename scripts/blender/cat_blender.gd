extends Area3D

@export var cat_manager: CatManager
@export var cat_scene: PackedScene
@export var cat_spawn_pos: Node3D

@export var corrupted_enchantment: Enchantment
@export var reroll_base_attack: int = 2
@export var reroll_base_health: int = 2
@export var reroll_enchantments: Array[Enchantment]

var cat1_data: CatData
var cat2_data: CatData

func _ready():
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D):
	if body is Cat:
		print(body.cat_name + " the " + body.enchantment.display_name + " cat entered the blender")
		
		# Putting in a corrupted cat will give back a base cat
		if body.enchantment == corrupted_enchantment:
			# If the blender already consumed a cat, spit it back out
			if cat1_data != null:
				cat_manager.spawn_cat(cat_spawn_pos.global_position, cat1_data)
				
			var reroll_cat_data = CatData.new()
			reroll_cat_data.cat_name = cat_manager.possible_names.pick_random()
			reroll_cat_data.base_attack = reroll_base_attack
			reroll_cat_data.base_health = reroll_base_health
			reroll_cat_data.enchantment = reroll_enchantments.pick_random()
			cat_manager.spawn_cat(cat_spawn_pos.global_position, reroll_cat_data)
			
			cat1_data = null
			cat2_data = null
			body.queue_free()
			return
		
		if cat1_data == null:
			cat1_data = body.get_cat_data()
			body.queue_free()
		elif cat2_data == null:
			cat2_data = body.get_cat_data()
			body.queue_free()
		
		if cat1_data != null and cat2_data != null:
			var result = CatData.new()
			result.cat_name = cat_manager.possible_names.pick_random()
			result.base_attack = cat1_data.base_attack + cat2_data.base_attack
			result.base_health = cat1_data.base_health + cat2_data.base_health
			result.enchantment = EnchantmentLibrary.combine_enchantments(cat1_data.enchantment, cat2_data.enchantment)
			cat_manager.spawn_cat(cat_spawn_pos.global_position, result)
			print("Created a " + result.enchantment.display_name + " cat")
			
			cat1_data = null
			cat2_data = null
