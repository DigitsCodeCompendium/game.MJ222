extends "res://scripts/cat/cat_bed.gd"

## CatBed variant with a combined attack/health display.
const STATS_UI = preload("res://scenes/cat_bed/cat_bed_stats.tscn")
var _stat_ui: Control
var _attached_ui: Control

## The bed owns the attached Control; replacing it frees the previous UI.
func attach_ui(ui: Control) -> void:
	if ui == _attached_ui:
		return
	var previous = detach_ui()
	if previous != null:
		previous.queue_free()
	if ui == null:
		return
	_attached_ui = ui
	var root: Control = $PanelViewport/Root
	if ui.get_parent() != null:
		ui.reparent(root, false)
	else:
		root.add_child(ui)
	ui.set_as_top_level(false)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.show()
	ui.tree_exiting.connect(_on_attached_ui_exiting)
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.albedo_texture = $PanelViewport.get_texture()
	$Panel.material_override = material
	$PanelViewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	$Panel.show()

func detach_ui() -> Control:
	var previous = _attached_ui
	_attached_ui = null
	if is_instance_valid(previous):
		previous.tree_exiting.disconnect(_on_attached_ui_exiting)
		previous.get_parent().remove_child(previous)
	else:
		previous = null
	$Panel.hide()
	$PanelViewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	$Panel.material_override = null
	return previous

func _on_attached_ui_exiting() -> void:
	_attached_ui = null
	$Panel.hide()
	$PanelViewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _update_occupant() -> void:
	super._update_occupant()
	if placed_cat is Cat:
		if not is_instance_valid(_stat_ui):
			_stat_ui = STATS_UI.instantiate()
			attach_ui(_stat_ui)
		_stat_ui.update_cat(placed_cat)

func _release_cat() -> void:
	super._release_cat()
	if is_instance_valid(_stat_ui) and _attached_ui == _stat_ui and is_inside_tree():
		var old_ui = detach_ui()
		old_ui.queue_free()
	_stat_ui = null
