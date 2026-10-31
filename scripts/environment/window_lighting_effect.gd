@tool
extends Node3D

var window_width: float = 2.5
var divider_width: float = 0.12
var pane_columns: int = 2
var floor_distance: float = 2.7
var floor_parent: Node3D
var floor_y: float = 0.0
var _sun_direction: Vector3 = Vector3(0, -1, 2).normalized()
var _receives_sunlight: bool = true
var glass_path: NodePath
## Solid decorative backings are replaced by the aperture mask for sunlight.
var window_backings: Array[NodePath] = []
var sunlight_energy: float = 0.65
var shaft_opacity: float = 0.075
var emission_energy: float = 0.65
var _beam_material: ShaderMaterial
var _shadow_defaults: Dictionary = {}
var _glass: MeshInstance3D
var _glass_material: StandardMaterial3D
var _day_color: Color
var _aperture_center: Vector3
var _shadow_layer: int = 0
var _active_theme: int = 0

func _ready() -> void:
	add_to_group("window_sunlight")

func refresh() -> void:
	for backing in _shadow_defaults:
		if is_instance_valid(backing):
			backing.cast_shadow = _shadow_defaults[backing]
	_shadow_defaults.clear()
	_glass = get_node_or_null(glass_path) as MeshInstance3D
	if _glass != null:
		var original = _glass.get_active_material(0) as StandardMaterial3D
		if original != null:
			_glass_material = original.duplicate()
			_day_color = original.albedo_color
			_glass.material_override = _glass_material
	for path in window_backings:
		var backing = get_node_or_null(path) as GeometryInstance3D
		if backing != null:
			var original_shadow = backing.cast_shadow
			for window in get_tree().get_nodes_in_group("window_sunlight"):
				if window != self and window._shadow_defaults.has(backing):
					original_shadow = window._shadow_defaults[backing]
					break
			_shadow_defaults[backing] = original_shadow
	if _glass != null:
		_shadow_defaults[_glass] = _glass.cast_shadow
	_beam_material = preload("res://scenes/environment/sunbeam_material.tres").duplicate()
	var ray_color: Color = _beam_material.get_shader_parameter("beam_color")
	ray_color.a = shaft_opacity
	_beam_material.set_shader_parameter("beam_color", ray_color)
	_configure_sunlight()
	_rebuild_shafts()
	$Beams/WindowFill.omni_range = maxf(6.0, floor_distance * 2.0)

func apply_theme(theme: int) -> void:
	_active_theme = theme
	var sunset = theme in [2, 3]
	var pink = theme == 3
	$Beams.visible = sunset and _receives_sunlight
	for backing in _shadow_defaults:
		if is_instance_valid(backing):
			backing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if sunset and _receives_sunlight else _shadow_defaults[backing]
	$Beams/WindowSunlight.light_color = Color(1, 0.5, 0.72, 1) if pink else Color(1, 0.86, 0.65, 1)
	$Beams/WindowFill.light_color = Color(1, 0.6, 0.8, 1) if pink else Color(1, 0.86, 0.71, 1)
	if _beam_material != null:
		var ray_color = Color(1, 0.55, 0.78, shaft_opacity) if pink else Color(1, 0.84, 0.63, shaft_opacity)
		_beam_material.set_shader_parameter("beam_color", ray_color)
	if _glass_material == null:
		return
	var sunset_glass = Color("efb4d4") if pink else Color("eed9b8")
	_glass_material.albedo_color = Color("273957") if theme == 1 else (sunset_glass if sunset else _day_color)
	_glass_material.emission_enabled = sunset
	_glass_material.emission = Color(1.0, 0.55, 0.78, 1.0) if pink else Color(1.0, 0.85, 0.65, 1.0)
	_glass_material.emission_energy_multiplier = emission_energy * (1.0 if _receives_sunlight else 0.2) if sunset else 0.0

func _configure_sunlight() -> void:
	var height = 1.6
	var center = Vector3.ZERO
	if _glass != null and _glass.mesh != null:
		height = _glass.mesh.get_aabb().size.y
		center = to_local(_glass.global_position)
	_aperture_center = center
	# Directional light represents a distant sun: every ray has the same slope.
	var light: DirectionalLight3D = $Beams/WindowSunlight
	light.light_energy = sunlight_energy
	var up = Vector3.FORWARD if absf(_sun_direction.dot(Vector3.UP)) > 0.999 else Vector3.UP
	light.global_basis = Basis.looking_at(_sun_direction, up)
	var local_direction = global_basis.inverse() * _sun_direction
	_receives_sunlight = local_direction.z > 0.01 and _sun_direction.y < -0.01
	# Give every aperture its own shadow layer, so neighbouring windows do not
	# block each other's sun. Ordinary room geometry stays on layer 1.
	if _shadow_layer == 0:
		var used: Array[int] = []
		for window in get_tree().get_nodes_in_group("window_sunlight"):
			if window != self:
				used.append(window._shadow_layer)
		for bit in range(19, 0, -1):
			if not used.has(1 << bit):
				_shadow_layer = 1 << bit
				break
	light.shadow_caster_mask = 1 | _shadow_layer
	light.light_cull_mask = 1 | _shadow_layer
	# Only shadows are rendered: these four pieces mask the sun to the opening.
	var margin = 128.0
	var mask: Node3D = $Beams/ApertureMask
	mask.position = center
	for side in ["Left", "Right", "Top", "Bottom"]:
		var mesh: MeshInstance3D = mask.get_node(side)
		mesh.layers = _shadow_layer
		var box = BoxMesh.new()
		if side == "Left" or side == "Right":
			box.size = Vector3(margin, height + margin * 2.0, 0.06)
			mesh.position.x = (window_width + margin) * (-0.5 if side == "Left" else 0.5)
		else:
			box.size = Vector3(window_width, margin, 0.06)
			mesh.position.y = (height + margin) * (0.5 if side == "Top" else -0.5)
		mesh.mesh = box

func _parallel_shaft(width: float, _shaft_offset: float) -> ArrayMesh:
	var height = _glass.mesh.get_aabb().size.y if _glass != null and _glass.mesh != null else 1.6
	var opening = [Vector3(-width/2, -height/2, 0), Vector3(width/2, -height/2, 0), Vector3(width/2, height/2, 0), Vector3(-width/2, height/2, 0)]
	var floor_points: Array[Vector3] = []
	var floor_world_y = floor_parent.to_global(Vector3(0, floor_y, 0)).y if is_instance_valid(floor_parent) else to_global(_aperture_center).y - floor_distance
	for corner in opening:
		var global_corner = to_global(_aperture_center + Vector3(_shaft_offset, 0, 0) + corner)
		var travel = maxf(0.0, (floor_world_y - global_corner.y) / _sun_direction.y)
		var endpoint = global_corner + _sun_direction * travel
		floor_points.append(to_local(endpoint) - _aperture_center - Vector3(_shaft_offset, 0, 0))
	var vertices = PackedVector3Array()
	var uv = PackedVector2Array()
	var indices = PackedInt32Array()
	for side in range(4):
		var next = (side + 1) % 4
		var first = vertices.size()
		vertices.append_array(PackedVector3Array([opening[side], opening[next], floor_points[next], floor_points[side]]))
		uv.append_array(PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]))
		indices.append_array(PackedInt32Array([first, first+1, first+2, first, first+2, first+3]))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _beam_material)
	return mesh

func _exit_tree() -> void:
	for backing in _shadow_defaults:
		if not is_instance_valid(backing):
			continue
		var still_needed = false
		for window in get_tree().get_nodes_in_group("window_sunlight"):
			if window != self and window._active_theme in [2, 3] and window._receives_sunlight and window._shadow_defaults.has(backing):
				still_needed = true
		backing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if still_needed else _shadow_defaults[backing]

func set_sun_direction(direction: Vector3) -> void:
	_sun_direction = direction.normalized() if not direction.is_zero_approx() else Vector3(0, -1, 2).normalized()
	_configure_sunlight()
	_rebuild_shafts()
	apply_theme(_active_theme)

func _rebuild_shafts() -> void:
	for previous in $Beams/Shafts.get_children():
		$Beams/Shafts.remove_child(previous)
		previous.queue_free()
	if not _receives_sunlight or _beam_material == null:
		return
	var count = maxi(pane_columns, 1)
	var pane_width = maxf(0.05, (window_width - divider_width * (count - 1)) / count)
	for index in range(count):
		var offset = -window_width/2 + pane_width/2 + index * (pane_width + divider_width)
		var beam = MeshInstance3D.new()
		beam.name = "Column%d" % (index + 1)
		beam.position = _aperture_center + Vector3(offset, 0, 0)
		beam.mesh = _parallel_shaft(pane_width, offset)
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam.layers = _shadow_layer
		$Beams/Shafts.add_child(beam)
