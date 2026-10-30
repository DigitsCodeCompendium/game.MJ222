extends Node

## The paths live beneath each staircase so they can be edited with the room.
@export var walking_speed: float = 6.0
@export var turn_speed: float = 8.0
@export var turn_lookahead: float = 0.8
@export var slide_height: float = 40.0
@export var fly_out_duration: float = 3.0
@export var fly_in_duration: float = 3.0
@export_range(0.1, 1.0, 0.05) var departure_disappear_progress: float = 0.9
var _title: Node3D
var _prep: Node3D
var _camera: Camera3D
var _title_camera: Camera3D
var _prep_camera: Camera3D
var _prep_ui: Array[CanvasLayer] = []
var _lighting: Node3D

func play(title: Node3D, destination: PackedScene, from_stairs: bool = false) -> void:
	_title = title
	var cat: Cat = title.get_node("MenuCat")
	title.starting_game = true
	title.get_node("MenuUI").hide()
	for bed in title.get_node("Beds").get_children():
		bed._release_cat()
		bed.process_mode = Node.PROCESS_MODE_DISABLED
	cat.set_physics_process(false)
	cat.set_process_input(false)
	cat.input_ray_pickable = false
	cat.velocity = Vector3.ZERO
	var original_layer = cat.collision_layer
	var original_mask = cat.collision_mask
	var original_avoidance = cat.navigation_agent.avoidance_enabled
	cat.navigation_agent.avoidance_enabled = false
	cat.collision_layer = 0
	cat.collision_mask = 0
	cat.ai_state = Cat.State.WANDERING
	cat.visual.animation_blend_time = 0.0
	cat.visual.play_behavior("wandering", "Walk")
	# A transparent full-screen control blocks both mouse and touch during travel.
	var input_layer = CanvasLayer.new()
	input_layer.layer = 100
	add_child(input_layer)
	var blocker = Control.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	input_layer.add_child(blocker)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var departure: Path3D = title.get_entrance_path()
	var departure_start = 0.0
	if from_stairs:
		var nearest = departure.curve.get_closest_offset(departure.to_local(cat.global_position))
		departure_start = nearest / departure.curve.get_baked_length()
	var first = departure.to_global(departure.curve.sample_baked(departure_start * departure.curve.get_baked_length()))
	var from = cat.global_position
	_face_direction(cat, first - from)
	var approach = create_tween()
	approach.tween_method(func(progress: float):
		cat.global_position = from.lerp(first, progress)
		_face_direction(cat, first - from)
	, 0.0, 1.0, 0.1 if from_stairs else maxf(from.distance_to(first) / walking_speed, 0.1))
	await approach.finished

	_prep = destination.instantiate()
	_prep.position.y = -slide_height
	# Keep one lighting rig alive while both rooms move beneath it.
	var duplicate_lighting = _prep.get_node("RoomLighting")
	_prep.remove_child(duplicate_lighting)
	duplicate_lighting.owner = null
	_lighting = title.get_node_or_null("RoomLighting")
	if _lighting != null:
		duplicate_lighting.free()
		_lighting.reparent(self)
	else:
		# Also accept an older title scene still open in the editor.
		for child in title.get_children():
			if child is WorldEnvironment:
				child.environment = null
			elif child is DirectionalLight3D:
				child.hide()
		_lighting = duplicate_lighting
		add_child(_lighting)
	_prep.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().root.add_child(_prep)
	for node in _prep.find_children("*", "CanvasLayer", true, false):
		if node.visible:
			_prep_ui.append(node)
			node.hide()
	_title_camera = title.get_node("Camera3D")
	_prep_camera = _prep.get_node("Player/Camera3D")
	_camera = _title_camera.duplicate()
	# The background belongs to the departing room, not the moving camera.
	for child in _camera.get_children():
		child.free()
	add_child(_camera)
	_camera.global_transform = _title_camera.global_transform
	_camera.make_current()
	var arrival: Path3D = _prep.get_node("Level/Room/StaircaseUp/WalkPath")
	# Anticipation and a slight overshoot give the rooms a springy slide.
	var exit_tween = create_tween()
	exit_tween.tween_interval(0.2)
	# A small wind-up, then accelerate offscreen without a long easing tail.
	exit_tween.tween_method(func(progress: float):
		var anticipation = 0.5
		var offset = progress * progress * ((anticipation + 1.0) * progress - anticipation)
		title.position.y = slide_height * offset
	, 0.0, 0.85, fly_out_duration * 0.85)
	var cat_data = cat.get_cat_data()
	await _walk(cat, departure, maxf(departure_disappear_progress, departure_start), departure_start)
	cat.hide()
	cat.queue_free()
	if exit_tween.is_running():
		await exit_tween.finished
	title.hide()
	# The title actor is gone; continue its entrance with a fresh prep actor.
	var manager: CatManager = _prep.get_node("Props/CatManager")
	cat_data.cat_name = manager.get_unique_name()
	# Only the first path segment is the stairs; the rest leads to the room centre.
	var stair_start = arrival.curve.get_point_position(0).lerp(arrival.curve.get_point_position(1), 0.25)
	var arrival_start = arrival.curve.get_closest_offset(stair_start) / arrival.curve.get_baked_length()
	cat = manager.spawn_cat(arrival.to_global(arrival.curve.sample_baked(arrival_start * arrival.curve.get_baked_length())), cat_data)
	# The prep room is disabled during its slide, but the walk animation must tick.
	cat.visual.process_mode = Node.PROCESS_MODE_PAUSABLE
	cat.set_physics_process(false)
	cat.set_process_input(false)
	cat.input_ray_pickable = false
	cat.navigation_agent.avoidance_enabled = false
	cat.collision_layer = 0
	cat.collision_mask = 0
	cat.ai_state = Cat.State.WANDERING
	cat.visual.animation_blend_time = 0.0
	cat.visual.play_behavior("wandering", "Walk")
	# Switch framing offscreen, then let the prep room overshoot and settle.
	_camera.projection = _prep_camera.projection
	_camera.keep_aspect = _prep_camera.keep_aspect
	_camera.fov = _prep_camera.fov
	_camera.size = _prep_camera.size
	_camera.near = _prep_camera.near
	_camera.far = _prep_camera.far
	_camera.global_transform = _prep_camera.global_transform
	_camera.global_position -= _prep.position
	var entry_tween = create_tween()
	entry_tween.tween_method(func(progress: float):
		var remaining = progress - 1.0
		var bounce = 0.5
		var offset = 1.0 + (bounce + 1.0) * remaining * remaining * remaining + bounce * remaining * remaining
		_prep.position.y = lerpf(-slide_height, 0.0, offset)
	, 0.0, 1.0, fly_in_duration)
	await _walk(cat, arrival, 1.0, arrival_start)
	if entry_tween.is_running():
		await entry_tween.finished
	_prep_camera.make_current()
	_camera.queue_free()
	_lighting.reparent(_prep)
	get_tree().current_scene = _prep
	title.queue_free()
	_prep.process_mode = Node.PROCESS_MODE_INHERIT
	for ui in _prep_ui:
		ui.show()
	cat.collision_layer = original_layer
	cat.collision_mask = original_mask
	cat.navigation_agent.avoidance_enabled = original_avoidance
	cat.set_process_input(true)
	cat.input_ray_pickable = true
	cat.set_physics_process(true)
	cat.global_rotation.x = 0.0
	cat.global_rotation.z = 0.0
	cat.visual.process_mode = Node.PROCESS_MODE_INHERIT
	cat._enter_behavior(Cat.State.IDLE)

func _walk(cat: Cat, path: Path3D, end_progress: float = 1.0, start_progress: float = 0.0) -> void:
	var length = path.curve.get_baked_length()
	var tween = create_tween()
	tween.tween_method(func(progress: float):
		var distance = progress * length
		cat.global_position = path.to_global(path.curve.sample_baked(distance))
		var behind = path.to_global(path.curve.sample_baked(maxf(distance - turn_lookahead * 0.5, 0.0)))
		var ahead = path.to_global(path.curve.sample_baked(minf(distance + turn_lookahead, length)))
		_face_direction(cat, ahead - behind)
	, start_progress, end_progress, length * (end_progress - start_progress) / walking_speed)
	await tween.finished

func _face_direction(cat: Cat, direction: Vector3) -> void:
	if direction.length_squared() > 0.00001:
		var target = Basis.looking_at(direction, Vector3.UP)
		var weight = 1.0 - exp(-turn_speed * get_process_delta_time())
		cat.global_basis = cat.global_basis.orthonormalized().slerp(target, weight)
