@tool
extends Node3D

## Each instance owns its meshes and materials; settings also update in the editor.
@export_range(0.1, 5.0, 0.05) var size_multiplier: float = 1.0:
	set(value):
		size_multiplier = value
		_update_tree()

@export_range(0.1, 12.0, 0.1) var trunk_height: float = 3.5:
	set(value):
		trunk_height = value
		_update_tree()

@export_range(0.05, 2.0, 0.05) var trunk_radius: float = 0.45:
	set(value):
		trunk_radius = value
		_update_tree()

@export_range(0.1, 12.0, 0.1) var crown_height: float = 4.5:
	set(value):
		crown_height = value
		_update_tree()

@export_range(0.1, 6.0, 0.1) var crown_radius: float = 2.4:
	set(value):
		crown_radius = value
		_update_tree()

@export_range(3, 24, 1) var radial_segments: int = 7:
	set(value):
		radial_segments = value
		_update_tree()

@export var bark_color: Color = Color(0.32, 0.22, 0.14):
	set(value):
		bark_color = value
		_update_tree()

@export var foliage_color: Color = Color(0.18, 0.35, 0.23):
	set(value):
		foliage_color = value
		_update_tree()

func _ready() -> void:
	_update_tree()

func _update_tree() -> void:
	if not is_node_ready():
		return
	$Model.scale = Vector3.ONE * size_multiplier
	var bark = StandardMaterial3D.new()
	bark.albedo_color = bark_color
	bark.roughness = 1.0
	var leaves = StandardMaterial3D.new()
	leaves.albedo_color = foliage_color
	leaves.roughness = 1.0
	var trunk = CylinderMesh.new()
	trunk.height = trunk_height
	trunk.bottom_radius = trunk_radius
	trunk.top_radius = trunk_radius * (0.25 / 0.45)
	trunk.radial_segments = radial_segments
	trunk.material = bark
	$Model/Trunk.mesh = trunk
	$Model/Trunk.position.y = trunk_height * 0.5
	var crown = CylinderMesh.new()
	crown.height = crown_height
	crown.bottom_radius = crown_radius
	crown.top_radius = 0.0
	crown.radial_segments = radial_segments
	crown.material = leaves
	$Model/LowerCrown.mesh = crown
	$Model/LowerCrown.position.y = trunk_height * 0.5 + crown_height * 0.5
	$Model/UpperCrown.mesh = crown
	$Model/UpperCrown.position.y = trunk_height * 0.5 + crown_height * (17.0 / 18.0)
	$Model/UpperCrown.scale = Vector3(0.73, 0.85, 0.73)
