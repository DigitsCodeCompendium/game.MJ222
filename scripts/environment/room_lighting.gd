@tool
extends Node3D

signal theme_changed(theme: int)
signal sun_direction_changed(direction: Vector3)
var _day_sun_basis: Basis
enum RoomTheme { DAY, NIGHT, GOLDEN_HOUR, PINK_SUNSET }
@export_enum("Day", "Night", "Golden hour", "Pink sunset") var theme: int = RoomTheme.DAY:
	set(value):
		theme = value
		if is_node_ready():
			_apply_theme()

## Angles in degrees, relative to the room. Azimuth 0 faces -Z,
## 90 faces +X; elevation 0 is the horizon and 90 is directly overhead.
@export_group("Sun")
@export_range(0.0, 360.0, 0.1) var sun_azimuth: float = 0.0:
	set(value):
		sun_azimuth = fposmod(value, 360.0)
		if is_node_ready():
			_sync_sun()

@export_range(-90.0, 90.0, 0.1) var sun_elevation: float = 26.565051:
	set(value):
		sun_elevation = clampf(value, -90.0, 90.0)
		if is_node_ready():
			_sync_sun()

func get_sun_ray_direction() -> Vector3:
	var azimuth = deg_to_rad(sun_azimuth)
	var elevation = deg_to_rad(sun_elevation)
	var towards_sun = Vector3(sin(azimuth) * cos(elevation), sin(elevation), -cos(azimuth) * cos(elevation))
	return -(global_basis * towards_sun).normalized()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_node_ready():
		_sync_sun()

func _sync_sun() -> void:
	var direction = get_sun_ray_direction()
	if theme in [RoomTheme.GOLDEN_HOUR, RoomTheme.PINK_SUNSET]:
		var up = Vector3.FORWARD if absf(direction.dot(Vector3.UP)) > 0.999 else Vector3.UP
		$DirectionalLight3D.global_basis = Basis.looking_at(direction, up)
	sun_direction_changed.emit(direction)

func _ready() -> void:
	set_notify_transform(true)
	add_to_group("room_lighting")
	_day_sun_basis = $DirectionalLight3D.basis
	$WorldEnvironment.environment = $WorldEnvironment.environment.duplicate()
	if not Engine.is_editor_hint():
		var manager = get_node_or_null("/root/GameManager")
		if manager != null and manager.room_theme >= 0:
			theme = manager.room_theme
	_apply_theme()

func _apply_theme() -> void:
	var environment: Environment = $WorldEnvironment.environment
	var sun: DirectionalLight3D = $DirectionalLight3D
	sun.shadow_enabled = true
	match theme:
		RoomTheme.NIGHT:
			environment.background_color = Color("182030")
			environment.ambient_light_color = Color("91a4ce")
			environment.ambient_light_energy = 0.22
			sun.light_color = Color("a5bce8")
			sun.light_energy = 0.035
			sun.rotation_degrees = Vector3(-45, -25, 0)
		RoomTheme.GOLDEN_HOUR:
			environment.background_color = Color("cfb1b3")
			environment.ambient_light_color = Color("e7deed")
			environment.ambient_light_energy = 0.7
			sun.light_color = Color("ffe5cf")
			sun.light_energy = 0.10
			# Window lights provide the direct sun and its shadows. The solid
			# decorative wall otherwise throws a huge shadow across the room.
			sun.shadow_enabled = false
			sun.basis = _day_sun_basis
		RoomTheme.PINK_SUNSET:
			environment.background_color = Color("8493b8")
			environment.ambient_light_color = Color("7597e5")
			environment.ambient_light_energy = 0.85
			sun.light_color = Color("91afff")
			sun.light_energy = 0.10
			# Window lights provide the direct sun and its shadows. The solid
			# decorative wall otherwise throws a huge shadow across the room.
			sun.shadow_enabled = false
			sun.basis = _day_sun_basis
		_:
			environment.background_color = Color(0.9059, 0.8667, 0.8157, 1)
			environment.ambient_light_color = Color(1, 0.945, 0.863, 1)
			environment.ambient_light_energy = 0.45
			sun.light_color = Color(1, 0.94, 0.85, 1)
			sun.light_energy = 0.2
			sun.basis = _day_sun_basis
	if not Engine.is_editor_hint():
		var manager = get_node_or_null("/root/GameManager")
		if manager != null:
			manager.room_theme = theme
	_sync_sun()
	theme_changed.emit(theme)
