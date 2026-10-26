extends Control

const CAT_VISUAL = preload("res://scenes/cat/cat_visual.tscn")
const MENU_PATH = "res://scenes/title/title_screen.tscn"
@onready var stage: Node3D = $WarmupViewport/Stage
@onready var progress: ProgressBar = $Center/Content/Progress
@onready var status: Label = $Center/Content/Status

func _ready() -> void:
	AudioManager.play_menu_music()
	# Headless runs have no rendered frames to wait for.
	if DisplayServer.get_name() == "headless":
		get_tree().change_scene_to_file.call_deferred(MENU_PATH)
		return
	_warm_up.call_deferred()

func _warm_up() -> void:
	await RenderingServer.frame_post_draw
	var enchantments = EnchantmentLibrary.all_enchantments
	progress.max_value = maxi(enchantments.size(), 1)
	for i in enchantments.size():
		var enchantment = enchantments[i]
		if enchantment == null:
			continue
		status.text = "Getting %s Squeeb ready..." % enchantment.display_name
		await RenderingServer.frame_post_draw
		var visual = CAT_VISUAL.instantiate()
		visual.enchantment = enchantment
		stage.add_child(visual)
		visual.play_loop("Idle")
		# Actually render textures, skinning, and particles to warm the renderer.
		if visual.active_face_set != null:
			for face in visual.active_face_set.textures:
				visual.set_face(face)
				await RenderingServer.frame_post_draw
		for animation in ["Walk", "Attack", "Sleep"]:
			visual.play_loop(animation)
			await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		visual.queue_free()
		await get_tree().process_frame
		progress.value = i + 1
	status.text = "Ready!"
	await RenderingServer.frame_post_draw
	get_tree().change_scene_to_file(MENU_PATH)
