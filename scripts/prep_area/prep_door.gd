class_name PrepAreaDoor
extends CollisionObject3D

signal on_clicked
signal disabled_clicked

@export var disabled: bool
@export var hover_color: Color = Color("55df78")
@export var open_duration: float = 0.75

var _hover_materials: Array[StandardMaterial3D] = []
var _original_colors: Array[Color] = []
var _opening = false
var _hovered = false
var _warned_balance: int = -1
@onready var tooltip: PanelContainer = $UI/Tooltip

func _ready() -> void:
	GameManager.money_changed.connect(reset_coin_warning)
	input_event.connect(_on_input_event)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	for part in ["Panel", "UpperInset", "LowerInset", "HandlePlate", "Handle"]:
		var mesh = $Hinge.get_node(part) as MeshInstance3D
		var material = mesh.get_active_material(0).duplicate() as StandardMaterial3D
		mesh.material_override = material
		_hover_materials.append(material)
		_original_colors.append(material.albedo_color)

func _set_hovered(hovered: bool) -> void:
	_hovered = hovered
	if not hovered:
		reset_coin_warning()
	for i in _hover_materials.size():
		_hover_materials[i].albedo_color = hover_color if hovered and not _opening else _original_colors[i]
	tooltip.visible = hovered and not _opening

func reset_coin_warning(_balance: int = 0) -> void:
	_warned_balance = -1
	$UI/Tooltip/Text.text = "To battle!"

func show_missing_team() -> void:
	_warned_balance = -1
	$UI/Tooltip/Text.text = "You can't go to battle without a team!\nPlace a Squeeb on a team bed."
	_process(0.0)

func confirm_remaining_coins(balance: int) -> bool:
	if balance <= 0 or _warned_balance == balance:
		return true
	_warned_balance = balance
	$UI/Tooltip/Text.text = "%d coin%s remaining!\nClick again to go to battle." % [balance, "" if balance == 1 else "s"]
	_process(0.0)
	return false

func _process(_delta: float) -> void:
	tooltip.visible = _hovered and not _opening
	if not tooltip.visible:
		return
	var camera = get_viewport().get_camera_3d()
	var anchor = to_global(Vector3(0, 4.9, 0))
	if camera == null or camera.is_position_behind(anchor):
		tooltip.hide()
		return
	tooltip.reset_size()
	var at = camera.unproject_position(anchor) - Vector2(tooltip.size.x / 2, tooltip.size.y + 12)
	var size = get_viewport().get_visible_rect().size
	tooltip.position = Vector2(clampf(at.x, 12, maxf(12, size.x - tooltip.size.x - 12)), clampf(at.y, 12, maxf(12, size.y - tooltip.size.y - 12)))

func open_door() -> void:
	_opening = true
	disabled = true
	input_ray_pickable = false
	_set_hovered(false)
	$CollisionShape3D.set_deferred("disabled", true)
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($Hinge, "rotation:y", deg_to_rad(-105.0), open_duration)
	await tween.finished

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if _opening:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if disabled:
			disabled_clicked.emit()
		else:
			on_clicked.emit()
