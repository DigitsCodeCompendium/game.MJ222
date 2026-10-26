extends PanelContainer

var data: CatData

func _ready() -> void:
	var enchantment = data.enchantment
	var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = enchantment.primary_color
	add_theme_stylebox_override("panel", style)
	$Content/Type.text = enchantment.display_name
	$Content/Stats.text = "%d ATK  %d HP" % [enchantment.base_attack + data.attack_offset, enchantment.base_health + data.health_offset]
	tooltip_text = "%s\n%s" % [enchantment.display_name, enchantment.description]
