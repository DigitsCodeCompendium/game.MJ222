extends Node3D

@export
var cat_name = "default_cat"

@onready
var click_box = $RigidBody3D/ClickBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	click_box.connect("clicked", _on_clicked)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_clicked():
	$DangoCatSKMesh.squish()
	print(cat_name + " was clicked")
