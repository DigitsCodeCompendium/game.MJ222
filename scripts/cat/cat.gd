extends Node3D

@export
var cat_name = "default_cat"

@export
var enchantment: Enchantment

@onready
var click_box = $RigidBody3D/ClickBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	click_box.connect("clicked", _on_clicked)
	if enchantment != null:
		# Ok this is probably an awful way to do this, just using it as a hack to test things out for now
		var mesh = $DangoCatSKMesh/Armature/Skeleton3D/Cube_004.mesh as ArrayMesh
		var material = mesh.surface_get_material(0) as StandardMaterial3D
		material = material.duplicate()
		material.albedo_color = enchantment.primary_color
		$DangoCatSKMesh/Armature/Skeleton3D/Cube_004.set_surface_override_material(0, material)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_clicked():
	$DangoCatSKMesh.squish()
	print(cat_name + " the " + enchantment.display_name + " cat was clicked")
