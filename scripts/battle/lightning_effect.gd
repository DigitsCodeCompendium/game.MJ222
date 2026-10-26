extends Node3D

@export var num_steps: int = 4
@export var thickness: float = 0.2
@export var turns_max_offset: float = 0.2

@export var vertices_per_ring: int = 24

func _ready():
	var rings = []
	var center_pos = Vector3.ZERO
	rings.append(_create_ring(center_pos))
	
	for i in range(num_steps):
		center_pos += Vector3.UP
		var radius = sqrt(randf()) * turns_max_offset
		var theta = randf() * TAU
		center_pos += Vector3(cos(theta), 0, sin(theta)) * turns_max_offset
		rings.append(_create_ring(center_pos))
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(num_steps):
		for j in range(rings[i].size()):
			st.add_vertex(rings[i][j])
			st.add_vertex(rings[i][(j+1) % vertices_per_ring])
			st.add_vertex(rings[i+1][j])
			
			st.add_vertex(rings[i][(j+1) % vertices_per_ring])
			st.add_vertex(rings[i+1][(j+1) % vertices_per_ring])
			st.add_vertex(rings[i+1][j])
	
	$MeshInstance3D.mesh = st.commit()
	
func _create_ring(center_pos: Vector3):
	var angle_per_vertex = TAU / vertices_per_ring
	var vertices = []
	for i in range(vertices_per_ring):
		var angle = i * angle_per_vertex
		var local_pos = Vector3(cos(angle), 0, sin(angle)) * thickness / 2
		vertices.append(center_pos + local_pos)
	return vertices
