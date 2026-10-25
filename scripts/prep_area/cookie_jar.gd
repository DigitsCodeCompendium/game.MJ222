extends Area3D

@export var cat_manager: CatManager
@export_range(0, 100, 1) var cookie_price: int = 1
@onready var panel: PanelContainer = $UI/Panel
@onready var hint: Label = $UI/Panel/Hint
@onready var cookie: Node3D = $HeldCookie
var _hovered = false
var _carrying = false
var _drop_pending = false
var _watching_cats: Dictionary = {}
var _hover_materials: Array[StandardMaterial3D] = []
var _original_colors: Array[Color] = []

func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	input_event.connect(_on_input_event)
	for child in get_children():
		if child is MeshInstance3D:
			var original = child.get_active_material(0) as StandardMaterial3D
			if original == null:
				continue
			var material = original.duplicate() as StandardMaterial3D
			child.material_override = material
			_hover_materials.append(material)
			_original_colors.append(material.albedo_color)
	cookie.hide()
	panel.hide()

func _set_hovered(hovered: bool) -> void:
	_hovered = hovered
	for i in _hover_materials.size():
		_hover_materials[i].albedo_color = Color("55df78") if hovered else _original_colors[i]

func _process(_delta: float) -> void:
	if cat_manager._starting_battle:
		_cancel_cookie()
		panel.hide()
		return
	if _carrying:
		_watch_cats()
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse = get_viewport().get_mouse_position()
	if _carrying:
		var at = Plane(Vector3.UP, 2.5).intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
		if at != null:
			cookie.global_position = at
	panel.visible = _hovered and not _carrying and not camera.is_position_behind($TooltipAnchor.global_position)
	if panel.visible:
		hint.text = "Squeeb cookie\nGives a Squeeb +1 attack and +1 defense\n%d coin%s - drag onto a Squeeb" % [cookie_price, "" if cookie_price == 1 else "s"]
		if not GameManager.can_afford(cookie_price):
			hint.text += "\nNot enough coins"
		panel.reset_size()
		var at = camera.unproject_position($TooltipAnchor.global_position) - Vector2(panel.size.x / 2, panel.size.y + 12)
		var size = get_viewport().get_visible_rect().size
		panel.position = Vector2(clampf(at.x, 12, maxf(12, size.x - panel.size.x - 12)), clampf(at.y, 12, maxf(12, size.y - panel.size.y - 12)))

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _carrying and not cat_manager._starting_battle and cat_manager.get_held_cat() == null:
			_carrying = true
			_watch_cats()
			cookie.show()
			panel.hide()
			_process(0.0)

func _input(event: InputEvent) -> void:
	if _carrying and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_drop_pending = true
		get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if not _drop_pending:
		return
	_drop_pending = false
	var camera = get_viewport().get_camera_3d()
	var target: Cat
	if camera != null:
		var mouse = get_viewport().get_mouse_position()
		var origin = camera.project_ray_origin(mouse)
		var query = PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(mouse) * camera.far)
		query.collide_with_areas = false
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		target = hit.get("collider") as Cat
	if not feed_cat(target):
		AudioManager.play_effect("huff")
	_cancel_cookie()

func feed_cat(cat: Cat) -> bool:
	if not _carrying or cat_manager._starting_battle or not is_instance_valid(cat):
		return false
	if cat.get_parent() != cat_manager or cat.is_queued_for_deletion() or cat.is_picked or cat._is_dropping:
		return false
	if not GameManager.try_spend_coins(cookie_price):
		return false
	cat.attack_offset += 1
	AudioManager.play_effect("purr")
	cat.health_offset += 1
	_cancel_cookie()
	return true

func _cancel_cookie() -> void:
	_carrying = false
	_drop_pending = false
	cookie.hide()
	_restore_cats()

func _watch_cats() -> void:
	for cat in cat_manager.get_cats():
		if not _watching_cats.has(cat):
			_watching_cats[cat] = {
				"state": cat.ai_state,
				"locked": cat.lock_ai_state,
				"time": cat._behavior_time_left,
				"resume_wander": cat._resume_wander_after_idle,
			}
		cat.lock_ai_state = true
		if cat.ai_state != Cat.State.WATCHING:
			cat._enter_behavior(Cat.State.WATCHING)

func _restore_cats() -> void:
	for cat in _watching_cats:
		if not is_instance_valid(cat) or cat.is_queued_for_deletion():
			continue
		var previous: Dictionary = _watching_cats[cat]
		cat.lock_ai_state = previous.locked
		# A departure animation owns the cats once battle starts.
		if is_instance_valid(cat_manager) and not cat_manager._starting_battle:
			cat._enter_behavior(previous.state)
			cat._behavior_time_left = previous.time
			cat._resume_wander_after_idle = previous.resume_wander
	_watching_cats.clear()

func _exit_tree() -> void:
	_restore_cats()
