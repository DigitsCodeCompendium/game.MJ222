extends Control

var camera: Camera3D
var attached_cat: BattleCat
var is_enemy: bool = false
@export var screen_offset: Vector2 = Vector2(0, 16)
@onready var panel: PanelContainer = $Panel
var _style: StyleBoxFlat

func _ready() -> void:
	_style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel.add_theme_stylebox_override("panel", _style)
	if is_enemy:
		_style.bg_color = Color(0.16, 0.09, 0.1, 0.95)
		_style.corner_radius_top_left = 3
		_style.corner_radius_top_right = 3
		$Panel/Content/Type.add_theme_font_size_override("font_size", 17)
	update_cat()

func _process(_delta: float) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(attached_cat):
		hide()
		return
	if camera.is_position_behind(attached_cat.global_position):
		hide()
		return
	show()
	var viewport_size = get_viewport().get_visible_rect().size
	var width = clampf(viewport_size.x / 10.0 - 8.0, 100.0, 160.0)
	panel.custom_minimum_size.x = width
	panel.size.x = width
	panel.reset_size()
	var at = camera.unproject_position(attached_cat.global_position) + screen_offset
	position = Vector2(at.x - panel.size.x / 2, minf(at.y, maxf(8, viewport_size.y - panel.size.y - 8)))

func update_cat() -> void:
	# The manager assigns data before adding this UI to the tree.
	if not is_node_ready() or not is_instance_valid(attached_cat):
		return
	$Panel/Content/Name.text = attached_cat.cat_name
	$Panel/Content/Name.visible = not is_enemy
	var enchantment = attached_cat.enchantment
	$Panel/Content/Type.text = enchantment.display_name if enchantment != null else "Squeeb"
	var color = enchantment.primary_color if enchantment != null else Color("a9c7d4")
	_style.border_color = color
	$Panel/Content/Type.modulate = color.lightened(0.4)
	$Panel/Content/Stats/Attack.text = "ATK %d" % attached_cat.attack
	$Panel/Content/Stats/Health.text = "HP %d" % attached_cat.health
	$Panel/Content/Status.visible = attached_cat.is_shrouded
	$Panel/Content/Status.text = "Shrouded" if attached_cat.is_shrouded else ""
