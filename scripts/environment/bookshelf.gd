@tool
extends Node3D

## Front faces +Z; dimensions rebuild in the editor. Book Seed makes layouts repeatable.
var _generated: Node3D
var _rebuild_pending = false

@export_range(1.0, 12.0, 0.1) var width: float = 4.0:
	set(value):
		width = maxf(0.5, value)
		_request_rebuild()

@export_range(1.0, 10.0, 0.1) var height: float = 4.2:
	set(value):
		height = maxf(0.5, value)
		_request_rebuild()

@export_range(0.3, 3.0, 0.05) var depth: float = 0.9:
	set(value):
		depth = maxf(0.2, value)
		_request_rebuild()

@export_range(1, 12, 1) var shelf_count: int = 4:
	set(value):
		shelf_count = clampi(value, 1, 12)
		_request_rebuild()

@export_range(0.05, 0.3, 0.01) var board_thickness: float = 0.14:
	set(value):
		board_thickness = maxf(0.02, value)
		_request_rebuild()

@export_range(0.0, 1.0, 0.05) var book_fill: float = 0.85:
	set(value):
		book_fill = clampf(value, 0.0, 1.0)
		_request_rebuild()

@export var book_seed: int = 12:
	set(value):
		book_seed = value
		_request_rebuild()

@export var show_back: bool = true:
	set(value):
		show_back = value
		_request_rebuild()

@export var generate_collisions: bool = true:
	set(value):
		generate_collisions = value
		_request_rebuild()

@export var wood_color: Color = Color(0.47, 0.31, 0.2):
	set(value):
		wood_color = value
		_request_rebuild()

@export var shelf_color: Color = Color(0.89, 0.81, 0.68):
	set(value):
		shelf_color = value
		_request_rebuild()

@export var book_colors: Array[Color] = [Color("819c74"), Color("b26853"), Color("6f929e"), Color("d2b36d"), Color("a28aab"), Color("d1c7aa")]:
	set(value):
		book_colors = value
		_request_rebuild()

@export_tool_button("Shuffle books") var shuffle_action: Callable = shuffle_books

func shuffle_books() -> void:
	book_seed = randi()

func _ready() -> void:
	_rebuild()

func _request_rebuild() -> void:
	if not is_node_ready() or _rebuild_pending:
		return
	_rebuild_pending = true
	_rebuild.call_deferred()

func _material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material

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
	var rng = RandomNumberGenerator.new()
	rng.seed = book_seed
	var wood = _material(wood_color)
	var trim = _material(shelf_color)
	var accent = _material(Color("dfc58b"))
	var palette: Array[StandardMaterial3D] = []
	for color in book_colors:
		palette.append(_material(color))
	if palette.is_empty():
		palette.append(_material(Color("819c74")))
	var thickness = minf(board_thickness, minf(width * 0.15, minf(depth * 0.25, height / (shelf_count + 1) * 0.3)))
	var inside_width = width - thickness * 2
	var opening_height = (height - thickness * (shelf_count + 1)) / shelf_count
	_box("LeftSide", Vector3(-width / 2 + thickness / 2, height / 2, 0), Vector3(thickness, height, depth), wood, generate_collisions)
	_box("RightSide", Vector3(width / 2 - thickness / 2, height / 2, 0), Vector3(thickness, height, depth), wood, generate_collisions)
	if show_back:
		_box("Back", Vector3(0, height / 2, -depth / 2 + thickness / 2), Vector3(inside_width, height, thickness), wood, generate_collisions)
	for row in range(shelf_count + 1):
		var board_y = thickness / 2 + row * (opening_height + thickness)
		_box("Shelf%02d" % row, Vector3(0, board_y, 0), Vector3(inside_width, thickness, depth), trim, generate_collisions)
	for row in range(shelf_count):
		var base_y = thickness + row * (opening_height + thickness)
		var x = -inside_width / 2 + 0.04
		var index = 0
		while x < inside_width / 2 - 0.08 and index < 256:
			var book_width = rng.randf_range(0.11, 0.25)
			if x + book_width > inside_width / 2 - 0.02:
				break
			if rng.randf() < book_fill:
				var book_height = opening_height * rng.randf_range(0.55, 0.92)
				var book_depth = (depth - thickness * 2) * rng.randf_range(0.7, 0.95)
				var z = -depth / 2 + thickness + book_depth / 2
				var book_x = x + book_width / 2
				var prefix = "Book%02d_%03d" % [row, index]
				_box(prefix, Vector3(book_x, base_y + book_height / 2, z), Vector3(book_width, book_height, book_depth), palette[rng.randi_range(0, palette.size() - 1)])
				for band in [0.18, 0.82]:
					_box(prefix + "Band%d" % int(band * 100), Vector3(book_x, base_y + book_height * band, z + book_depth / 2 + 0.004), Vector3(book_width * 0.85, 0.025, 0.01), accent)
			x += book_width + rng.randf_range(0.015, 0.045)
			index += 1

func _box(node_name: String, at: Vector3, dimensions: Vector3, material: Material, collision: bool = false) -> void:
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
