@tool
extends Node3D

@export var fallback_environment: PackedScene
var active_environment: Node3D

func _ready() -> void:
	var scene = fallback_environment
	if not Engine.is_editor_hint():
		var manager = get_node_or_null("/root/GameManager")
		if manager != null:
			if manager.is_test_env:
				if manager.test_environment != null:
					scene = manager.test_environment
			else:
				var stage = manager.get_current_stage()
				if stage != null and stage.environment_scene != null:
					scene = stage.environment_scene
	if scene == null:
		return
	var instance = scene.instantiate()
	if not instance is Node3D:
		push_error("Stage environment must have a Node3D root.")
		instance.free()
		return
	active_environment = instance
	add_child(active_environment, false, Node.INTERNAL_MODE_BACK)
