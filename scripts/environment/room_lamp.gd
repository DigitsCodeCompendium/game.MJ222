@tool
extends Node3D

var _is_on: bool = false
var _manually_switched: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		$ClickArea.input_event.connect(_on_input_event)
	_bind_lighting.call_deferred()

func _bind_lighting() -> void:
	var lighting = owner.get_node_or_null("RoomLighting") if owner != null else null
	if lighting == null:
		lighting = get_tree().get_first_node_in_group("room_lighting")
	if lighting == null:
		return
	if not lighting.theme_changed.is_connected(_apply_theme):
		lighting.theme_changed.connect(_apply_theme)
	_apply_theme(lighting.theme)

func _apply_theme(theme: int) -> void:
	if not _manually_switched:
		_is_on = theme == 1
	_update_light()

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_manually_switched = true
		_is_on = not _is_on
		_update_light()
		get_viewport().set_input_as_handled()

func _update_light() -> void:
	$WarmLight.visible = _is_on
	$PoolLight.visible = _is_on
	var material: StandardMaterial3D = $Bulb.mesh.material
	material.emission_energy_multiplier = 1.8 if _is_on else 0.0
	var shade: StandardMaterial3D = $Shade.mesh.material
	shade.emission_energy_multiplier = 0.28 if _is_on else 0.0
