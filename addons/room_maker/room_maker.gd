@tool
extends Node3D

const Bone = preload("res://addons/room_maker/room_bone.gd")

@export_range(0.5, 15, 0.1) var wall_height: float = 4.0:
	set(value):
		wall_height = maxf(0.5, value)
		queue_rebuild()
@export_range(0.05, 2, 0.05) var wall_thickness: float = 0.25:
	set(value):
		wall_thickness = maxf(0.05, value)
		queue_rebuild()
@export var wall_material: Material:
	set(value):
		wall_material = value
		queue_rebuild()
@export var floor_material: Material:
	set(value):
		floor_material = value
		queue_rebuild()
@export var generate_collisions: bool = true:
	set(value):
		generate_collisions = value
		queue_rebuild()
## Openings snap to nearby parallel walls within this distance.
@export_range(0.02, 2, 0.05) var opening_snap_distance: float = 0.35:
	set(value):
		opening_snap_distance = value
		queue_rebuild()

var _pending: bool = false
var _generated: Node3D
var _outlines: Array[PackedVector2Array] = []

func _ready() -> void:
	rebuild()

func queue_rebuild() -> void:
	if not is_inside_tree() or _pending:
		return
	_pending = true
	rebuild.call_deferred()

func get_bones() -> Array[Node3D]:
	var result: Array[Node3D] = []
	_collect(self, result)
	return result

func _collect(parent: Node, result: Array[Node3D]) -> void:
	for child in parent.get_children():
		if child == _generated:
			continue
		if child is Bone:
			result.append(child)
		_collect(child, result)

func _point(bone: Node3D, point: Vector2) -> Vector2:
	var local = to_local(bone.to_global(Vector3(point.x, 0, point.y)))
	return Vector2(local.x, local.z)

func get_room_outlines() -> Array[PackedVector2Array]:
	var groups: Dictionary = {}
	for bone in get_bones():
		if bone.kind != 0:
			continue
		var polygon = PackedVector2Array()
		for point in bone.outline():
			polygon.append(_point(bone, point))
		if Geometry2D.triangulate_polygon(polygon).is_empty():
			continue
		if Geometry2D.is_polygon_clockwise(polygon):
			polygon.reverse()
		if not groups.has(bone.room_id):
			groups[bone.room_id] = []
		groups[bone.room_id].append(polygon)
	var result: Array[PackedVector2Array] = []
	for polygons in groups.values():
		# Repeatedly merge intersecting rectangles, including branches joining earlier islands.
		var changed = true
		while changed:
			changed = false
			for i in range(polygons.size()):
				for j in range(i + 1, polygons.size()):
					var merged = Geometry2D.merge_polygons(polygons[i], polygons[j])
					if merged.size() == 1:
						polygons[i] = merged[0]
						polygons.remove_at(j)
						changed = true
						break
				if changed:
					break
		for polygon in polygons:
			result.append(polygon)
	return result

func rebuild() -> void:
	_pending = false
	if not is_inside_tree():
		return
	if is_instance_valid(_generated):
		remove_child(_generated)
		_generated.queue_free()
	_generated = Node3D.new()
	_generated.name = "GeneratedRoom"
	add_child(_generated, false, Node.INTERNAL_MODE_BACK)
	var wall = wall_material
	if wall == null:
		wall = StandardMaterial3D.new()
		wall.albedo_color = Color("eed9b6")
	var floor_mat = floor_material
	if floor_mat == null:
		floor_mat = StandardMaterial3D.new()
		floor_mat.albedo_color = Color("b87e50")
	_outlines = get_room_outlines()
	var openings: Array[Dictionary] = []
	for bone in get_bones():
		if bone.kind == 1:
			openings.append({"a": _point(bone, bone.start), "b": _point(bone, bone.end), "height": bone.opening_height})
	var edges: Array[Dictionary] = []
	for polygon in _outlines:
		_floor(polygon, floor_mat)
		for i in range(polygon.size()):
			edges.append({"a": polygon[i], "b": polygon[(i + 1) % polygon.size()]})
	# Split shared boundaries before deduplication, even when rooms differ in size.
	var seen: Dictionary = {}
	for edge in edges:
		var length: float = edge.a.distance_to(edge.b)
		if length < 0.01:
			continue
		var direction: Vector2 = (edge.b - edge.a) / length
		var limits: Array[float] = [0.0, length]
		for other in edges:
			for point in [other.a, other.b]:
				if absf((point - edge.a).cross(direction)) < 0.001:
					var distance: float = (point - edge.a).dot(direction)
					if distance > 0.001 and distance < length - 0.001:
						limits.append(distance)
		limits.sort()
		for i in range(limits.size() - 1):
			if limits[i + 1] - limits[i] < 0.001:
				continue
			var a: Vector2 = edge.a + direction * limits[i]
			var b: Vector2 = edge.a + direction * limits[i + 1]
			var key_a = str(a.snapped(Vector2.ONE * 0.001))
			var key_b = str(b.snapped(Vector2.ONE * 0.001))
			var key = key_a + ":" + key_b if key_a < key_b else key_b + ":" + key_a
			if seen.has(key):
				continue
			seen[key] = true
			_wall_with_openings(a, b, openings, wall)
	update_gizmos()

func _floor(polygon: PackedVector2Array, material: Material) -> void:
	var triangles = Geometry2D.triangulate_polygon(polygon)
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, triangles.size(), 3):
		var a = polygon[triangles[i]]
		var b = polygon[triangles[i + 1]]
		var c = polygon[triangles[i + 2]]
		# Clockwise when seen from above, with an upward normal.
		var points = [a, b, c]
		if (b - a).cross(c - a) < 0:
			points = [a, c, b]
		for p in points:
			surface.set_normal(Vector3.UP)
			surface.set_uv(p * 0.25)
			surface.add_vertex(Vector3(p.x, 0, p.y))
	var instance = MeshInstance3D.new()
	instance.name = "Floor"
	instance.mesh = surface.commit()
	instance.material_override = material
	_generated.add_child(instance)
	if generate_collisions:
		instance.create_trimesh_collision()

func _wall_with_openings(a: Vector2, b: Vector2, openings: Array[Dictionary], material: Material) -> void:
	var length = a.distance_to(b)
	if length < 0.01:
		return
	var direction = (b - a) / length
	var cuts: Array[Dictionary] = []
	var limits: Array[float] = [0.0, length]
	for opening in openings:
		var delta: Vector2 = opening.b - opening.a
		if delta.length() < 0.01 or absf(delta.normalized().dot(direction)) < 0.98:
			continue
		if maxf(absf((opening.a - a).cross(direction)), absf((opening.b - a).cross(direction))) > opening_snap_distance:
			continue
		var x = (opening.a - a).dot(direction)
		var y = (opening.b - a).dot(direction)
		var begin = clampf(minf(x, y), 0, length)
		var finish = clampf(maxf(x, y), 0, length)
		if finish - begin < 0.01:
			continue
		cuts.append({"begin": begin, "end": finish, "height": minf(opening.height, wall_height)})
		limits.append(begin)
		limits.append(finish)
	limits.sort()
	for i in range(limits.size() - 1):
		var begin = limits[i]
		var finish = limits[i + 1]
		if finish - begin < 0.01:
			continue
		var midpoint = (begin + finish) * 0.5
		var bottom = 0.0
		for cut in cuts:
			if midpoint > cut.begin and midpoint < cut.end:
				bottom = maxf(bottom, cut.height)
		if wall_height - bottom < 0.01:
			continue
		var center = a + direction * midpoint
		var box = BoxMesh.new()
		box.size = Vector3(finish - begin, wall_height - bottom, wall_thickness)
		box.material = material
		var instance = MeshInstance3D.new()
		instance.name = "Lintel" if bottom > 0 else "Wall"
		instance.mesh = box
		instance.position = Vector3(center.x, (wall_height + bottom) * 0.5, center.y)
		instance.rotation.y = -atan2(direction.y, direction.x)
		_generated.add_child(instance)
		if generate_collisions:
			var body = StaticBody3D.new()
			var collider = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = box.size
			collider.shape = shape
			instance.add_child(body)
			body.add_child(collider)
