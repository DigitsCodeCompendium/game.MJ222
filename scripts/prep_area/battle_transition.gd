extends CanvasLayer

@export var fade_duration: float = 0.6

func block_input() -> void:
	$Fade.show()

func go_to_battle() -> void:
	var tree = get_tree()
	var tween = create_tween()
	tween.tween_property($Fade, "color:a", 1.0, fade_duration)
	await tween.finished
	# Keep the fade alive across the scene change so battle fades in smoothly.
	reparent(tree.root)
	GameManager.start_battle()
	await tree.scene_changed
	tween = create_tween()
	tween.tween_property($Fade, "color:a", 0.0, fade_duration)
	await tween.finished
	queue_free()
