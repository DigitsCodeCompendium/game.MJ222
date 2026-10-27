@tool
extends Node3D

## Generated geometry is rebuilt from these properties, including in the editor.
var _rebuild_pending = false
var _generated: Node3D

@export_range(0.5, 12.0, 0.1) var width: float = 2.6:
	set(value):
		width = maxf(0.01, value)
		_request_rebuild()

@export_range(0.05, 2.0, 0.05) var step_height: float = 0.4:
	set(value):
		step_height = maxf(0.01, value)
		_request_rebuild()

@export_range(1, 64, 1) var step_count: int = 8:
	set(value):
		step_count = maxi(1, value)
		_request_rebuild()

@export_range(0.15, 3.0, 0.05) var step_length: float = 0.55:
	set(value):
		step_length = maxf(0.01, value)
		_request_rebuild()

@export_enum("Up", "Down") var direction: int = 0:
	set(value):
		direction = value
		_request_rebuild()

@export var show_railings: bool = false:
	set(value):
		show_railings = value
		_request_rebuild()

@export_range(0.3, 3.0, 0.05) var railing_height: float = 1.05:
	set(value):
		railing_height = maxf(0.01, value)
		_request_rebuild()

@export var generate_collisions: bool = true:
	set(value):
		generate_collisions = value
		_request_rebuild()

@export var wood_color: Color = Color(0.56, 0.37, 0.23):
	set(value):
		wood_color = value
		_request_rebuild()

@export var trim_color: Color = Color(0.89, 0.82, 0.7):
	set(value):
		trim_color = value
		_request_rebuild()

func _ready() -> void:
	_rebuild()

func _request_rebuild() -> void:
	if not is_node_ready() or _rebuild_pending:
		return
	_rebuild_pending = true
	_rebuild.call_deferred()

func _rebuild() -> void:
	_rebuild_pending = false
	if not is_inside_tree():
		return
	if is_instance_valid(_generated):
		remove_child(_generated)
		_generated.queue_free()
	_generated = Node3D.new()
	_generated.name = "Generated"
	add_child(_generated)
	var wood = StandardMaterial3D.new()
	wood.albedo_color = wood_color
	wood.roughness = 0.85
	var trim = StandardMaterial3D.new()
	trim.albedo_color = trim_color
	trim.roughness = 0.9
	var sign_y = 1.0 if direction == 0 else -1.0
	var tread_thickness = minf(0.1, step_height * 0.25)
	# Both directions have a continuous, closed body beneath the treads.
	var base_height = minf(0.0, sign_y * step_count * step_height) - 0.2
	_add_box("Landing", Vector3(0, -0.1, -0.15), Vector3(width, 0.2, 0.5), wood, generate_collisions)
	for i in range(1, step_count + 1):
		var top = sign_y * i * step_height
		var z = (i - 0.5) * step_length
		var body_top = top - tread_thickness
		var body_height = body_top - base_height
		_add_box("Body%02d" % i, Vector3(0, base_height + body_height / 2, z), Vector3(width, body_height, step_length), trim, generate_collisions)
		_add_box("Step%02d" % i, Vector3(0, top - tread_thickness / 2, z), Vector3(width + 0.04, tread_thickness, step_length + 0.03), wood, generate_collisions)
	if not show_railings:
		return
	var rise = sign_y * step_count * step_height
	var run = step_count * step_length
	var rail_length = Vector2(run, rise).length()
	for side in [-1.0, 1.0]:
		var x = side * (width / 2 - 0.05)
		var prefix = "Left" if side < 0 else "Right"
		for i in range(step_count + 1):
			if i % 2 != 0 and i != step_count:
				continue
			_add_box("%sPost%d" % [prefix, i], Vector3(x, sign_y * i * step_height + railing_height / 2, i * step_length), Vector3(0.14, railing_height, 0.14), trim)
		var rail = _add_box(prefix + "Handrail", Vector3(x, rise / 2 + railing_height, run / 2), Vector3(0.18, 0.18, rail_length), wood)
		rail.rotation.x = -atan2(rise, run)

func _add_box(node_name: String, at: Vector3, dimensions: Vector3, material: Material, collision: bool = false) -> Node3D:
	var mesh = BoxMesh.new()
	mesh.size = dimensions
	mesh.material = material
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	var node: Node3D = instance
	if collision:
		var body = StaticBody3D.new()
		body.add_child(instance)
		var collider = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = dimensions
		collider.shape = shape
		body.add_child(collider)
		node = body
	node.name = node_name
	node.position = at
	_generated.add_child(node)
	return node
