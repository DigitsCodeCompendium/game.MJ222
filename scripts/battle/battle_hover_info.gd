extends "res://scripts/cat/cat_pickup_info.gd"

@export var battle_manager: Node3D
var _owns_pause = false

func _process(_delta: float) -> void:
	var tree = get_tree()
	if tree.paused and not _owns_pause:
		panel.hide()
		return
	var camera = get_viewport().get_camera_3d()
	var hovered = _find_hovered_cat(camera, get_viewport().get_mouse_position())
	_show_hovered_cat(hovered, camera)

func _find_hovered_cat(camera: Camera3D, mouse: Vector2) -> BattleCat:
	var hovered: BattleCat
	if camera != null and is_instance_valid(battle_manager) and not battle_manager.is_battle_over() and get_viewport().gui_get_hovered_control() == null:
		var origin = camera.project_ray_origin(mouse)
		var query = PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(mouse) * camera.far)
		query.collide_with_areas = true
		var hit = battle_manager.get_world_3d().direct_space_state.intersect_ray(query)
		hovered = hit.get("collider") as BattleCat
		if hovered != null and (hovered.is_queued_for_deletion() or not hovered in battle_manager.get_all_cats()):
			hovered = null
	return hovered

func _show_hovered_cat(hovered: BattleCat, camera: Camera3D) -> void:
	var tree = get_tree()
	if hovered != null:
		if not tree.paused:
			_owns_pause = true
			tree.paused = true
	else:
		_resume_battle()
	_show_cat(hovered, camera)

func _resume_battle() -> void:
	if _owns_pause:
		get_tree().paused = false
		_owns_pause = false

func _exit_tree() -> void:
	_resume_battle()
