extends Control

var camera: Camera3D
var attached_cat: BattleCat

func _process(delta):
	if camera == null or attached_cat == null:
		pass
	
	var screen_pos = camera.unproject_position(attached_cat.global_position)
	position = screen_pos

func update_cat():
	$PanelTop/NameLabel.text = attached_cat.cat_name
	$PanelTop/EnchantmentLabel.text = attached_cat.enchantment.display_name
	$PanelTop/EnchantmentLabel.modulate = attached_cat.enchantment.primary_color
	$PanelTop/StatusLabel.text = "Shrouded" if attached_cat.is_shrouded else ""
	$AttackLabel.text = "A: %s" % attached_cat.attack
	$HealthLabel.text = "H: %s" % attached_cat.health
