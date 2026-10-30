extends Node3D

## Bounds are local to the stairs; only completed player drops activate them.
@export_enum("Start game", "Return to title") var action: int = 0
@export var size: Vector3 = Vector3(3, 5, 6)
var _triggered = false

func _ready() -> void:
	get_tree().node_added.connect(_watch_cat)
	for node in get_tree().root.find_children("*", "CharacterBody3D", true, false):
		_watch_cat(node)

func _watch_cat(node: Node) -> void:
	if node is Cat and not node.dropped.is_connected(_on_cat_dropped):
		node.dropped.connect(_on_cat_dropped)

func contains_point(world_position: Vector3) -> bool:
	var point = to_local(world_position).abs()
	return point.x <= size.x * 0.5 and point.y <= size.y * 0.5 and point.z <= size.z * 0.5

func _on_cat_dropped(cat: Cat) -> void:
	if _triggered or not can_process() or not contains_point(cat.global_position):
		return
	_triggered = true
	_activate.call_deferred()

func _activate() -> void:
	if action == 0:
		var title = get_tree().current_scene
		if title != null and title.has_method("_select_bed"):
			title._select_bed(0, true)
	else:
		GameManager.end_run()
