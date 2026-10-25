class_name PrepAreaDoor
extends CollisionObject3D

signal on_clicked
signal disabled_clicked

@export var disabled: bool
@export var hover_color: Color = Color(0.3, 1.0, 0.35)
@export var open_duration: float = 0.75

var _hover_materials: Array[StandardMaterial3D] = []
var _original_colors: Array[Color] = []
var _opening = false

func _ready() -> void:
	input_event.connect(_on_input_event)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	for part in ["Panel", "UpperInset", "LowerInset"]:
		var mesh = $Hinge.get_node(part) as MeshInstance3D
		var material = mesh.get_active_material(0).duplicate() as StandardMaterial3D
		mesh.material_override = material
		_hover_materials.append(material)
		_original_colors.append(material.albedo_color)

func _set_hovered(hovered: bool) -> void:
	for i in _hover_materials.size():
		_hover_materials[i].albedo_color = hover_color if hovered and not _opening else _original_colors[i]

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
