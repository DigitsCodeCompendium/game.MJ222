@tool
extends Node3D

## Nested rectangular rooms. Shapes with the same room_id share an outline.
@export_enum("Room", "Opening") var kind: int = 0:
	set(value):
		kind = value
		notify_property_list_changed()
		_changed()
@export var room_id: StringName = &"main":
	set(value):
		room_id = value
		_changed()
## Local corners are saved atomically; the Inspector exposes floor-plan coordinates.
@export_storage var corners: PackedVector2Array = PackedVector2Array():
	set(value):
		corners = value.duplicate()
		_changed()

@export_group("Room corners (X, Z)")
@export var corner_a: Vector2:
	get:
		return _inspector_corner(0)
	set(value):
		_set_inspector_corner(0, value)
@export var corner_b: Vector2:
	get:
		return _inspector_corner(1)
	set(value):
		_set_inspector_corner(1, value)
@export var corner_c: Vector2:
	get:
		return _inspector_corner(2)
	set(value):
		_set_inspector_corner(2, value)
@export var corner_d: Vector2:
	get:
		return _inspector_corner(3)
	set(value):
		_set_inspector_corner(3, value)

@export_group("Opening endpoints (local X, Z)")
@export var start: Vector2 = Vector2(-4, 0):
	set(value):
		start = value
		_changed()
@export var end: Vector2 = Vector2(4, 0):
	set(value):
		end = value
		_changed()

# Read old scenes without losing their layout. These fields are hidden and are
# used only until the old rectangle has been converted to four stored corners.
@export_storage var left_width: float = 3.0
@export_storage var right_width: float = 3.0
@export_storage var start_padding: float = 0.0
@export_storage var end_padding: float = 0.0
@export_group("Opening")
## Blue segment runs ALONG a wall; its length is the opening width.
@export_range(0.25, 10, 0.1) var opening_height: float = 2.6:
	set(value):
		opening_height = maxf(0.25, value)
		_changed()

func _ready() -> void:
	if kind == 0:
		_ensure_corners()
	set_notify_transform(true)
	_changed()

func _exit_tree() -> void:
	var maker = get_maker()
	if maker != null:
		maker.queue_rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_changed()

func get_maker() -> Node3D:
	var parent = get_parent()
	while parent != null:
		if parent.has_method("get_room_outlines"):
			return parent
		parent = parent.get_parent()
	return null

func _changed() -> void:
	if not is_inside_tree():
		return
	update_gizmos()
	var maker = get_maker()
	if maker != null:
		maker.queue_rebuild()

func direction() -> Vector2:
	return (end - start).normalized() if start.distance_to(end) > 0.01 else Vector2.RIGHT

func _legacy_outline() -> PackedVector2Array:
	var along = direction()
	var side = Vector2(-along.y, along.x)
	var a = start - along * start_padding
	var b = end + along * end_padding
	return PackedVector2Array([a - side * left_width, b - side * left_width,
		b + side * right_width, a + side * right_width])

func _ensure_corners() -> void:
	if corners.size() != 4:
		corners = _legacy_outline()

func outline() -> PackedVector2Array:
	return corners.duplicate() if corners.size() == 4 else _legacy_outline()

func center() -> Vector2:
	var points = outline()
	return (points[0] + points[2]) * 0.5

func move_corner(index: int, point: Vector2) -> void:
	var points = outline()
	var opposite = (index + 2) % 4
	var next = (index + 1) % 4
	var previous = (index + 3) % 4
	var anchor = points[opposite]
	var u = (points[next] - anchor).normalized()
	var v = (points[previous] - anchor).normalized()
	# Keep the opposite corner fixed; neighbours slide along the existing axes.
	var width = maxf(0.25, (point - anchor).dot(u))
	var depth = maxf(0.25, (point - anchor).dot(v))
	points[next] = anchor + u * width
	points[previous] = anchor + v * depth
	points[index] = anchor + u * width + v * depth
	corners = points

func translate_room(delta: Vector2, original: PackedVector2Array) -> void:
	var points = original.duplicate()
	for i in range(points.size()):
		points[i] += delta
	corners = points

func _inspector_corner(index: int) -> Vector2:
	var point = outline()[index]
	var maker = get_maker()
	if maker == null or not is_inside_tree():
		return point
	var plan_point = maker.to_local(to_global(Vector3(point.x, 0, point.y)))
	return Vector2(plan_point.x, plan_point.z)

func _set_inspector_corner(index: int, point: Vector2) -> void:
	var maker = get_maker()
	if maker != null and is_inside_tree():
		var local = to_local(maker.to_global(Vector3(point.x, 0, point.y)))
		point = Vector2(local.x, local.z)
	move_corner(index, point)

func _validate_property(property: Dictionary) -> void:
	var property_name: String = property.name
	if property_name in ["corner_a", "corner_b", "corner_c", "corner_d"]:
		# Save the complete corner array once, never four sequential resize edits.
		property.usage = PROPERTY_USAGE_EDITOR if kind == 0 else PROPERTY_USAGE_NONE
	if property_name in ["start", "end", "opening_height"] and kind == 0:
		property.usage = PROPERTY_USAGE_STORAGE

func edit_state() -> Dictionary:
	if kind == 0:
		return {"corners": outline()}
	return {"start": start, "end": end}

func restore_state(state: Dictionary) -> void:
	for property in state:
		set(property, state[property])
