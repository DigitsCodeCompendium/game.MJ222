extends StaticBody3D

@export var cat_packed_scene: PackedScene
@export var cat_container_node: Node

@onready var spawn_point = $"Spawn Point"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_cat():
	var cat_instance = cat_packed_scene.instantiate()
	cat_container_node.add_child(cat_instance)

func _on_spawn_cat_button_pressed() -> void:
	spawn_cat()
