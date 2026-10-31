@tool
extends Node3D

## The origin is the bottom centre of the frame; +Z faces into the room.
## Floor Y is measured in the window parent's coordinates.
var _rebuild_pending = false
var _lighting: Node
@export_group("Geometry")
@export_range(0.6, 16.0, 0.05) var width: float = 5.0:
	set(value):
		width = value
		_request_rebuild()

@export_range(0.6, 16.0, 0.05) var height: float = 3.0:
	set(value):
		height = value
		_request_rebuild()

@export_range(0.02, 0.5, 0.01) var frame_thickness: float = 0.2:
	set(value):
		frame_thickness = value
		_request_rebuild()

@export_range(0.02, 0.5, 0.01) var depth: float = 0.18:
	set(value):
		depth = value
		_request_rebuild()

@export_range(1, 8, 1) var columns: int = 2:
	set(value):
		columns = value
		_request_rebuild()

@export_range(1, 8, 1) var rows: int = 2:
	set(value):
		rows = value
		_request_rebuild()

@export_range(0.02, 0.5, 0.01) var divider_width: float = 0.12:
	set(value):
		divider_width = value
		_request_rebuild()

@export_group("Sill")
@export var show_sill: bool = true:
	set(value):
		show_sill = value
		_request_rebuild()

@export_range(0.0, 2.0, 0.05) var sill_depth: float = 0.74:
	set(value):
		sill_depth = value
		_request_rebuild()

@export_group("Placement")
@export var floor_y: float = 0.0:
	set(value):
		floor_y = value
		_request_rebuild()

@export_group("Colours")
@export var frame_color: Color = Color(0.659, 0.525, 0.396, 1):
	set(value):
		frame_color = value
		_request_rebuild()

@export var trim_color: Color = Color(0.98, 0.92, 0.81, 1):
	set(value):
		trim_color = value
		_request_rebuild()

@export var glass_color: Color = Color(0.64, 0.81, 0.85, 1):
	set(value):
		glass_color = value
		_request_rebuild()

@export_group("Sunlight")
@export_range(0.0, 4.0, 0.05) var sunlight_energy: float = 0.65:
	set(value):
		sunlight_energy = value
		_request_rebuild()

@export_range(0.0, 0.5, 0.005) var ray_opacity: float = 0.075:
	set(value):
		ray_opacity = value
		_request_rebuild()

@export_range(0.0, 4.0, 0.05) var window_glow: float = 0.65:
	set(value):
		window_glow = value
		_request_rebuild()

func _ready() -> void:
	set_notify_local_transform(true)
	_rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		_request_rebuild()

func _request_rebuild() -> void:
	if not is_inside_tree() or not is_node_ready() or _rebuild_pending:
		return
	_rebuild_pending = true
	_rebuild.call_deferred()

func _rebuild() -> void:
	_rebuild_pending = false
	if not is_inside_tree():
		return
	var geometry: Dictionary = $Geometry.rebuild({
		"width": width,
		"height": height,
		"frame_thickness": frame_thickness,
		"depth": depth,
		"columns": columns,
		"rows": rows,
		"divider_width": divider_width,
		"sill_depth": sill_depth,
		"frame_color": frame_color,
		"trim_color": trim_color,
		"glass_color": glass_color,
		"show_sill": show_sill,
	})
	var h: float = geometry.height
	var opening: Vector2 = geometry.opening
	var effect = $WindowLight
	effect.position = Vector3(0,h/2,depth/2+0.12)
	effect.window_width = opening.x
	effect.pane_columns = geometry.columns
	effect.divider_width = geometry.divider
	effect.floor_distance = maxf(0.1, position.y + h/2 - floor_y)
	effect.floor_parent = get_parent()
	effect.floor_y = floor_y
	effect.glass_path = NodePath("../Geometry/Glass")
	effect.window_backings.clear()
	# Find the wall behind the window automatically; no per-scene effect wiring.
	var behind = to_global(Vector3(0,h/2,-0.2))
	for candidate in get_parent().find_children("*", "MeshInstance3D", true, false):
		if is_ancestor_of(candidate) or candidate.mesh == null:
			continue
		if candidate.mesh.get_aabb().grow(0.06).has_point(candidate.to_local(behind)):
			effect.window_backings.append(effect.get_path_to(candidate))
			break
	effect.sunlight_energy = sunlight_energy
	effect.shaft_opacity = ray_opacity
	effect.emission_energy = window_glow
	effect.refresh()
	_bind_lighting()

func _bind_lighting() -> void:
	var lighting: Node
	var ancestor = get_parent()
	while ancestor != null:
		lighting = ancestor.get_node_or_null("RoomLighting")
		if lighting != null:
			break
		ancestor = ancestor.get_parent()
	if lighting == null:
		lighting = get_tree().get_first_node_in_group("room_lighting")
	if is_instance_valid(_lighting) and _lighting != lighting:
		if _lighting.theme_changed.is_connected(_apply_theme):
			_lighting.theme_changed.disconnect(_apply_theme)
		if _lighting.sun_direction_changed.is_connected(_sun_direction_changed):
			_lighting.sun_direction_changed.disconnect(_sun_direction_changed)
	_lighting = lighting
	if lighting != null:
		if not lighting.theme_changed.is_connected(_apply_theme):
			lighting.theme_changed.connect(_apply_theme)
		if not lighting.sun_direction_changed.is_connected(_sun_direction_changed):
			lighting.sun_direction_changed.connect(_sun_direction_changed)
		_sun_direction_changed(lighting.get_sun_ray_direction())
		_apply_theme(lighting.theme)
	else:
		_apply_theme(0)

func _apply_theme(theme: int) -> void:
	$WindowLight.apply_theme(theme)

func _sun_direction_changed(direction: Vector3) -> void:
	$WindowLight.set_sun_direction(direction)
