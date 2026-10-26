extends CanvasLayer

@export var fade_duration: float = 0.5

func change_scene(scene: PackedScene) -> void:
	var tree = get_tree()
	var tween = create_tween()
	tween.tween_property($Fade, "color:a", 1.0, fade_duration)
	await tween.finished
	tree.change_scene_to_packed(scene)
	await tree.scene_changed
	tween = create_tween()
	tween.tween_property($Fade, "color:a", 0.0, fade_duration)
	await tween.finished
	queue_free()
