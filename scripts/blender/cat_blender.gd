extends Area3D

@export var cat_manager: CatManager
@export var cat_spawn_pos: Node3D
@export var corrupted_enchantment: Enchantment
@export var reroll_enchantments: Array[Enchantment]
@export var show_bed_labels: bool = true

@onready var input_a: CatBed = $InputA
@onready var input_b: CatBed = $InputB
@onready var output_bed: CatBed = $Output
@onready var panel: PanelContainer = $OutputUI/Panel
@onready var result_label: Label = $OutputUI/Panel/Content/Result
@onready var stats_label: Label = $OutputUI/Panel/Content/Stats
@onready var description_label: Label = $OutputUI/Panel/Content/Description
@onready var hint_label: Label = $OutputUI/Panel/Content/Hint
@onready var core: MeshInstance3D = $Device/Core

var _preview_cache: Dictionary = {}
var _preview_results: Array[CatData] = []
var _preview_key = ""
var _merging = false
var _panel_style: StyleBoxFlat
var _core_material: StandardMaterial3D
var _orb_hovered = false

func _ready() -> void:
	if not show_bed_labels:
		for bed in [input_a, input_b, output_bed]:
			bed.get_node("Label").hide()
	input_event.connect(_on_device_input)
	mouse_entered.connect(_set_orb_hovered.bind(true))
	mouse_exited.connect(_set_orb_hovered.bind(false))
	_panel_style = panel.get_theme_stylebox("panel").duplicate()
	panel.add_theme_stylebox_override("panel", _panel_style)
	_core_material = core.get_active_material(0).duplicate()
	core.material_override = _core_material
	for control in panel.find_children("*", "Control", true, false):
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.hide()

func _input_cats() -> Array[Cat]:
	var cats: Array[Cat] = []
	for bed in [input_a, input_b]:
		var cat = bed.placed_cat as Cat
		if is_instance_valid(cat) and not cat.is_queued_for_deletion() and not cat.is_picked and not cat._is_dropping and bed.contains_point(cat.global_position):
			cats.append(cat)
	return cats

func _pair_key(cats: Array[Cat]) -> String:
	var parts: Array[String] = []
	for cat in cats:
		parts.append("%s:%s:%s:%s" % [cat.get_instance_id(), cat.enchantment.get_instance_id() if cat.enchantment != null else 0, cat.attack_offset, cat.health_offset])
	parts.sort()
	return "|".join(parts)

func _build_results(cats: Array[Cat]) -> Array[CatData]:
	var results: Array[CatData] = []
	for cat in cats:
		if cat.enchantment == null:
			return results
	var has_corrupted = cats.any(func(cat): return cat.enchantment == corrupted_enchantment)
	if has_corrupted:
		var choices = reroll_enchantments.filter(func(e): return e != null)
		if choices.is_empty():
			return results
		# Preserve the old cleansing behavior: reroll corrupted cats, return other inputs.
		for cat in cats:
			var data = cat.get_cat_data()
			if cat.enchantment == corrupted_enchantment:
				data.enchantment = choices.pick_random()
				data.cat_name = ""
			results.append(data)
	elif cats.size() == 2:
		var data = CatData.new()
		data.cat_name = ""
		data.enchantment = EnchantmentLibrary.combine_enchantments(cats[0].enchantment, cats[1].enchantment)
		data.attack_offset = maxi(cats[0].attack_offset, cats[1].attack_offset)
		data.health_offset = maxi(cats[0].health_offset, cats[1].health_offset)
		if data.enchantment != null:
			results.append(data)
	return results

func _refresh_preview() -> void:
	var cats = _input_cats()
	var key = _pair_key(cats)
	if key != _preview_key:
		_preview_key = key
		_preview_results.clear()
		if not cats.is_empty():
			if not _preview_cache.has(key):
				_preview_cache[key] = _build_results(cats)
			_preview_results.assign(_preview_cache[key])
	panel.visible = _orb_hovered
	if cats.is_empty():
		result_label.text = "Place cats on the input beds"
		stats_label.text = ""
		description_label.text = "Place two cats on the beds to preview their merge."
		hint_label.text = "Merging costs %d coins." % GameManager.MERGE_PRICE
		_panel_style.border_color = Color("a9c7d4")
		return
	if _preview_results.is_empty():
		result_label.text = "Waiting for a second cat"
		stats_label.text = cats[0].cat_name + " is ready"
		description_label.text = "Place another cat on the empty input bed to preview the merge."
		hint_label.text = "Pick either cat up to cancel."
		_panel_style.border_color = Color("a9c7d4")
		return
	var names: Array[String] = []
	var stats: Array[String] = []
	var descriptions: Array[String] = []
	for data in _preview_results:
		names.append(data.enchantment.display_name)
		stats.append("%s: Attack %d / Health %d" % [data.enchantment.display_name, data.enchantment.base_attack + data.attack_offset, data.enchantment.base_health + data.health_offset])
		descriptions.append(data.enchantment.description if not data.enchantment.description.is_empty() else "No special ability.")
	result_label.text = " + ".join(names)
	stats_label.text = "\n".join(stats)
	description_label.text = "\n\n".join(descriptions)
	if _output_is_occupied():
		hint_label.text = "Pick up the output cat before merging again"
	elif not GameManager.can_afford(GameManager.MERGE_PRICE):
		hint_label.text = "Not enough coins — merging costs %d coins" % GameManager.MERGE_PRICE
	else:
		hint_label.text = "Click the glowing core to merge — %d coins" % GameManager.MERGE_PRICE
	var color = _preview_results[0].enchantment.primary_color
	_panel_style.border_color = color

func _set_orb_hovered(hovered: bool) -> void:
	_orb_hovered = hovered
	_refresh_preview()
	_update_core_color()

func _update_core_color() -> void:
	var color = Color("a9c7d4")
	if not _preview_results.is_empty():
		color = _preview_results[0].enchantment.primary_color.lightened(0.3)
	if _orb_hovered:
		color = Color("55df78")
	_core_material.albedo_color = color
	_core_material.emission = color
	_core_material.emission_energy_multiplier = 0.6 if _orb_hovered else (0.8 if not _preview_results.is_empty() else 0.15)

func _process(_delta: float) -> void:
	_refresh_preview()
	_update_core_color()
	if not panel.visible:
		return
	var camera = get_viewport().get_camera_3d()
	if camera == null or camera.is_position_behind(global_position):
		panel.hide()
		return
	panel.reset_size()
	var viewport_size = get_viewport().get_visible_rect().size
	var at = camera.unproject_position(to_global(Vector3(0, 2.5, 0))) - Vector2(panel.size.x * 0.5, panel.size.y + 12)
	at.x = clampf(at.x, 12, maxf(12, viewport_size.x - panel.size.x - 12))
	at.y = clampf(at.y, 12, maxf(12, viewport_size.y - panel.size.y - 12))
	panel.position = at

func _on_device_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not _merging:
		_merging = true
		merge_cats.call_deferred()

func _output_is_occupied() -> bool:
	output_bed._update_occupant()
	return is_instance_valid(output_bed.placed_cat) and not output_bed.placed_cat.is_queued_for_deletion()

func merge_cats() -> void:
	_refresh_preview()
	var cats = _input_cats()
	if not is_instance_valid(cat_manager) or _preview_results.is_empty() or cats.is_empty() or _output_is_occupied():
		_merging = false
		return
	if cat_manager._starting_battle or not GameManager.try_spend_coins(GameManager.MERGE_PRICE):
		_merging = false
		return
	var results: Array[CatData] = _preview_results.duplicate()
	# Queued inputs immediately release their manager slots and names.
	for cat in cats:
		cat.queue_free()
	input_a._release_cat()
	input_b._release_cat()
	for index in range(results.size()):
		# Cleansing can return a second cat; keep it on a now-empty input bed.
		var bed = output_bed if index == 0 else input_a
		var cat = cat_manager.spawn_cat(bed.get_placement_position(), results[index])
		if cat != null:
			cat.global_rotation.y = bed.global_rotation.y
			bed.try_place_cat(cat, bed == output_bed)
	_preview_key = ""
	_preview_results.clear()
	_preview_cache.clear()
	panel.hide()
	_merging = false
