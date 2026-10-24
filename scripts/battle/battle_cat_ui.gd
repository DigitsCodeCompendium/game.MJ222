extends Control

var camera: Camera3D
var attached_cat: BattleCat

func _process(delta):
	if camera == null or attached_cat == null:
		pass
	
	var screen_pos = camera.unproject_position(attached_cat.global_position)
	position = screen_pos

func update_cat():
	$EnchantmentLabel.text = "Enchantment: %s" % attached_cat.enchantment.display_name
	$EnchantmentLabel.modulate = attached_cat.enchantment.primary_color
	$HealthLabel.text = "Health: %s" % attached_cat.health
	$AttackLabel.text = "Attack: %s" % attached_cat.attack
