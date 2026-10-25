class_name CatBed
extends Area3D

signal cat_placed(cat: Node3D)

@export var bed_label: String = "Cat bed"
@export var cushion_color: Color = Color("b7ca97")
@export var lock_cat_to_bed: bool = false

var placed_cat: Node3D
var _owns_ai_lock = false
var _previous_ai_lock = false
var _highlighted = false
var _flash_tween: Tween
@onready var cushion: MeshInstance3D = $Cushion

func _ready() -> void:
	add_to_group("cat_beds")
	$Label.text = bed_label
	var material = StandardMaterial3D.new()
	material.albedo_color = cushion_color
	material.roughness = 0.9
	cushion.material_override = material
	body_exited.connect(_on_body_exited)

func _on_body_exited(body: Node3D) -> void:
	if body == placed_cat:
		_release_cat()

func _release_ai_lock() -> void:
	if _owns_ai_lock and is_instance_valid(placed_cat):
		placed_cat.lock_ai_state = _previous_ai_lock
	_owns_ai_lock = false

func _release_cat() -> void:
	_release_ai_lock()
	placed_cat = null

func _exit_tree() -> void:
	_release_cat()

func _is_held_or_dropping(body: Node3D) -> bool:
	return body.get("is_picked") == true or body.get("_is_dropping") == true or body.get_meta("is_picked", false) or body.get_meta("is_dropping", false)

func _is_on_bed(body: Node3D) -> bool:
	var height = to_local(body.global_position).y
	return contains_point(body.global_position) and height >= -0.15 and height <= 0.85

func _update_occupant() -> void:
	if not is_instance_valid(placed_cat):
		_release_cat()
		return
	if _is_held_or_dropping(placed_cat) or not _is_on_bed(placed_cat):
		_release_cat()
		return
	if not lock_cat_to_bed:
		_release_ai_lock()
	elif placed_cat is Cat:
		if not _owns_ai_lock:
			_previous_ai_lock = placed_cat.lock_ai_state
			_owns_ai_lock = true
			placed_cat.lock_ai_state = true
			placed_cat._enter_behavior(Cat.State.WATCHING)
		placed_cat.global_position = get_placement_position()

func contains_point(world_position: Vector3) -> bool:
	var local = to_local(world_position)
	return absf(local.x) < 1.65 and absf(local.z) < 1.3

func get_placement_position() -> Vector3:
	return $PlacementPoint.global_position

func set_highlighted(highlighted: bool) -> void:
	_highlighted = highlighted
	if _flash_tween != null and _flash_tween.is_running():
		return
	cushion.material_override.albedo_color = cushion_color.lightened(0.25) if highlighted else cushion_color

func flash_empty() -> void:
	if _flash_tween != null and _flash_tween.is_running():
		return
	_flash_tween = create_tween()
	for i in range(2):
		_flash_tween.tween_property(cushion.material_override, "albedo_color", Color("ff4545"), 0.12)
		_flash_tween.tween_interval(0.12)
		_flash_tween.tween_property(cushion.material_override, "albedo_color", cushion_color, 0.18)
		_flash_tween.tween_interval(0.12)
	_flash_tween.tween_callback(func():
		cushion.material_override.albedo_color = cushion_color.lightened(0.25) if _highlighted else cushion_color)

func _physics_process(_delta: float) -> void:
	_update_occupant()
	if is_instance_valid(placed_cat):
		return
	for body in get_overlapping_bodies():
		try_place_cat(body)
		if is_instance_valid(placed_cat):
			break

func try_place_cat(body: Node3D) -> void:
	_update_occupant()
	if is_instance_valid(placed_cat):
		return
	if not (body is Cat or body.is_in_group("cats")):
		return
	if _is_held_or_dropping(body) or not _is_on_bed(body):
		return
	placed_cat = body
	_update_occupant()
	cat_placed.emit(body)
