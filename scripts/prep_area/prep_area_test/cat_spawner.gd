extends Area3D

@export var cat_manager: CatManager
@onready var panel: PanelContainer = $UI/Panel
@onready var hint: Label = $UI/Panel/Hint
var _hovered = false
var _emerging = false
var _materials: Array[StandardMaterial3D] = []
var _colors: Array[Color] = []

func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	input_event.connect(_on_input_event)
	for mesh in $Model.get_children():
		if mesh is MeshInstance3D:
			var material = mesh.get_active_material(0).duplicate() as StandardMaterial3D
			mesh.material_override = material
			_materials.append(material)
			_colors.append(material.albedo_color)
	panel.hide()

func _set_hovered(hovered: bool) -> void:
	_hovered = hovered
	for i in _materials.size():
		_materials[i].albedo_color = Color("55df78") if hovered else _colors[i]

func _process(_delta: float) -> void:
	panel.visible = _hovered and not cat_manager._starting_battle
	if not panel.visible:
		return
	hint.text = "Adopt a Squeeb: %d coin%s" % [GameManager.CAT_PRICE, "" if GameManager.CAT_PRICE == 1 else "s"]
	if _emerging:
		hint.text += "\nA Squeeb is coming out!"
	elif not cat_manager.can_spawn_cat():
		hint.text += "\nSqueeb limit reached"
	elif not GameManager.can_afford(GameManager.CAT_PRICE):
		hint.text += "\nNot enough coins"
	else:
		hint.text += "\nClick to adopt"
	var camera = get_viewport().get_camera_3d()
	if camera == null or camera.is_position_behind($TooltipAnchor.global_position):
		panel.hide()
		return
	panel.reset_size()
	var at = camera.unproject_position($TooltipAnchor.global_position) - Vector2(panel.size.x / 2, panel.size.y + 12)
	var size = get_viewport().get_visible_rect().size
	panel.position = Vector2(clampf(at.x, 12, maxf(12, size.x - panel.size.x - 12)), clampf(at.y, 12, maxf(12, size.y - panel.size.y - 12)))

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		spawn_cat.call_deferred()

func spawn_cat() -> Cat:
	if _emerging:
		AudioManager.play_effect("huff")
		return null
	var cat = cat_manager.buy_cat($SpawnPoint.global_position)
	if cat == null:
		AudioManager.play_effect("huff")
		return null
	_emerging = true
	cat.set_physics_process(false)
	cat.input_ray_pickable = false
	cat.navigation_agent.avoidance_enabled = false
	cat.global_rotation = Vector3(0, global_rotation.y + PI, 0)
	cat._enter_behavior(Cat.State.WANDERING)
	var tween = create_tween()
	tween.tween_property(cat, "global_position", $ExitPoint.global_position, 1.2)
	# Loop the walk animation while normal AI is paused.
	while tween.is_running():
		if not is_instance_valid(cat) or cat.is_queued_for_deletion():
			_emerging = false
			return null
		cat._sync_state_animation()
		await get_tree().process_frame
	if not cat_manager._starting_battle:
		cat.navigation_agent.avoidance_enabled = true
		cat.input_ray_pickable = true
		cat.set_physics_process(true)
		cat._enter_behavior(Cat.State.IDLE)
	_emerging = false
	return cat
