extends Control

var _last_values: Array = []
var _style: StyleBoxFlat

func _ready() -> void:
	_style = $Center/Card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	$Center/Card.add_theme_stylebox_override("panel", _style)

func update_cat(cat: Cat) -> void:
	var attack = cat.attack_offset
	var health = cat.health_offset
	if cat.enchantment != null:
		attack += cat.enchantment.base_attack
		health += cat.enchantment.base_health
	var color = cat.enchantment.primary_color if cat.enchantment != null else Color("a9c7d4")
	var values = [attack, health, color]
	if values == _last_values:
		return
	_last_values = values
	$Center/Card/Stats.text = "%d/%d" % [attack, health]
	$Center/Card/Stats.add_theme_color_override("font_color", Color(1, 0.95, 0.84))
	_style.border_color = color
