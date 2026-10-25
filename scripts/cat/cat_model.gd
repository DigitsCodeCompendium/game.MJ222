class_name CatModel
extends Node3D

## Configure these when a variant uses a different model or material layout.
## Set a surface index to -1 to preserve that part's authored materials.
@export_node_path("MeshInstance3D") var body_mesh_path = NodePath("Armature/Skeleton3D/Cat")
@export_node_path("MeshInstance3D") var paw_mesh_path = NodePath("Armature/Skeleton3D/Cat")
@export_node_path("MeshInstance3D") var face_mesh_path = NodePath("Armature/Skeleton3D/Cat")
@export var body_surface: int = 0
@export var paw_surface: int = 1
@export var face_surface: int = 2

func get_surface_mesh(part: String) -> MeshInstance3D:
	var path: NodePath = get(part + "_mesh_path")
	var mesh = get_node_or_null(path) as MeshInstance3D
	var surface: int = get(part + "_surface")
	if mesh == null or mesh.mesh == null or surface < 0 or surface >= mesh.mesh.get_surface_count():
		return null
	return mesh
