@tool
extends Node3D

@export_range(0, 10000, 1) var star_count: int = 70:
	set(value):
		star_count = clampi(value, 0, 10000)
		_request_rebuild()
@export var random_seed: int = 229:
	set(value):
		random_seed = value
		_request_rebuild()
## Stars are distributed inside this box, centred on the node.
@export var field_size: Vector3 = Vector3(190, 58, 25):
	set(value):
		field_size = value.abs()
		_request_rebuild()
@export_range(0.001, 2.0, 0.005) var min_radius: float = 0.10:
	set(value):
		min_radius = maxf(0.001, value)
		_request_rebuild()
@export_range(0.001, 2.0, 0.005) var max_radius: float = 0.15:
	set(value):
		max_radius = maxf(0.001, value)
		_request_rebuild()
@export_color_no_alpha var star_color: Color = Color(0.86, 0.89, 1.0):
	set(value):
		star_color = value
		_request_rebuild()
@export_color_no_alpha var bright_star_color: Color = Color(1.0, 0.82, 0.59):
	set(value):
		bright_star_color = value
		_request_rebuild()
@export_range(0.0, 1.0, 0.01) var bright_star_fraction: float = 0.12:
	set(value):
		bright_star_fraction = clampf(value, 0.0, 1.0)
		_request_rebuild()

var _field: MultiMeshInstance3D
var _pending: bool = false

func _ready() -> void:
	rebuild()

func _request_rebuild() -> void:
	if not is_node_ready() or _pending:
		return
	_pending = true
	rebuild.call_deferred()

func rebuild() -> void:
	_pending = false
	if not is_inside_tree():
		return
	if not is_instance_valid(_field):
		_field = get_node_or_null("GeneratedStars") as MultiMeshInstance3D
	if not is_instance_valid(_field):
		_field = MultiMeshInstance3D.new()
		_field.name = "GeneratedStars"
		_field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_field, false, Node.INTERNAL_MODE_BACK)
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	var mesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = material
	var stars = MultiMesh.new()
	stars.transform_format = MultiMesh.TRANSFORM_3D
	stars.use_colors = true
	stars.mesh = mesh
	stars.instance_count = star_count
	var random = RandomNumberGenerator.new()
	random.seed = random_seed
	for i in range(star_count):
		var at = Vector3(random.randf_range(-0.5, 0.5), random.randf_range(-0.5, 0.5), random.randf_range(-0.5, 0.5)) * field_size
		var bright = random.randf() < bright_star_fraction
		var radius = random.randf_range(min_radius, maxf(min_radius, max_radius)) * (1.4 if bright else 1.0)
		stars.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * radius), at))
		stars.set_instance_color(i, bright_star_color if bright else star_color)
	_field.multimesh = stars
