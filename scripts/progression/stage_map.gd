extends Area3D

@export var hover_color: Color = Color("55df78")
var _material: StandardMaterial3D
var _base_color: Color

@onready var overlay: Control = $Menu/Overlay
var _owns_pause: bool = false

func _ready() -> void:
	add_to_group("stage_maps")
	overlay.hide()
	_material = $Block.get_active_material(0).duplicate() as StandardMaterial3D
	_base_color = _material.albedo_color
	$Block.material_override = _material
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	input_event.connect(_on_input_event)
	$Menu/Overlay/Margin/Panel/Content/Close.pressed.connect(close)

func _set_hovered(hovered: bool) -> void:
	_material.albedo_color = hover_color if hovered and not overlay.visible else _base_color

func _on_input_event(_camera: Node, event: InputEvent, _at: Vector3, _normal: Vector3, _shape: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		open()
		get_viewport().set_input_as_handled()

func open() -> void:
	if overlay.visible or get_tree().paused:
		return
	_owns_pause = true
	get_tree().paused = true
	overlay.show()
	_set_hovered(false)
	$Menu/Overlay/Margin/Panel/Content/Close.grab_focus()

func close() -> void:
	overlay.hide()
	if _owns_pause:
		get_tree().paused = false
		_owns_pause = false

func _input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if _owns_pause:
		get_tree().paused = false
