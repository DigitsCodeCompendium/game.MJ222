extends CanvasLayer

@export var cat_manager: CatManager
@export var screen_offset: Vector2 = Vector2(85, -65)

@onready var panel: PanelContainer = $Panel
@onready var name_label: Label = $Panel/Content/CatName
@onready var stats_label: Label = $Panel/Content/Stats
@onready var enchantment_label: Label = $Panel/Content/Enchantment
@onready var description_label: Label = $Panel/Content/Description
var _panel_style: StyleBoxFlat
var _default_border_color: Color

func _ready() -> void:
	_panel_style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	_default_border_color = _panel_style.border_color
	panel.add_theme_stylebox_override("panel", _panel_style)
	panel.hide()
	# The tooltip must never intercept pickup/release or camera input.
	for control in panel.find_children("*", "Control", true, false):
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	var shown_cat: Cat
	var camera = get_viewport().get_camera_3d()
	if is_instance_valid(cat_manager):
		shown_cat = cat_manager.get_held_cat()
		if shown_cat == null and get_viewport().gui_get_hovered_control() == null:
			shown_cat = cat_manager.get_hovered_bed_cat(camera, get_viewport().get_mouse_position())
	if shown_cat == null or camera == null or camera.is_position_behind(shown_cat.global_position):
		panel.hide()
		return
	_update_content(shown_cat)
	panel.show()
	var viewport_size = get_viewport().get_visible_rect().size
	panel.custom_minimum_size.x = minf(300.0, maxf(150.0, viewport_size.x - 24.0))
	panel.reset_size()
	var anchor = camera.unproject_position(shown_cat.global_position + Vector3.UP * 0.8)
	var at = anchor + screen_offset
	# Flip to the left when there isn't enough space beside the cat on the right.
	if at.x + panel.size.x > viewport_size.x - 12:
		at.x = anchor.x - screen_offset.x - panel.size.x
	at.x = clampf(at.x, 12.0, maxf(12.0, viewport_size.x - panel.size.x - 12.0))
	at.y = clampf(at.y, 12.0, maxf(12.0, viewport_size.y - panel.size.y - 12.0))
	panel.position = at

func _update_content(cat: Cat) -> void:
	name_label.text = cat.cat_name
	var enchantment = cat.enchantment
	_panel_style.border_color = enchantment.primary_color if enchantment != null else _default_border_color
	var attack = cat.attack_offset
	var health = cat.health_offset
	if enchantment != null:
		attack += enchantment.base_attack
		health += enchantment.base_health
		enchantment_label.text = enchantment.display_name
		enchantment_label.add_theme_color_override("font_color", enchantment.primary_color.lightened(0.4))
		description_label.text = enchantment.description if not enchantment.description.strip_edges().is_empty() else "No special ability."
	else:
		enchantment_label.text = "No enchantment"
		enchantment_label.add_theme_color_override("font_color", Color.WHITE)
		description_label.text = "No special ability."
	stats_label.text = "Attack  %d     Health  %d" % [attack, health]
