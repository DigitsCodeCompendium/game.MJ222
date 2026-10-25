class_name Cat
extends CharacterBody3D

@export var cat_name = "default_cat"
@export var movement_speed: float = 4.0
@export var pickup_height: float = 2.0
@export var pickup_speed: float = 6.0
@export var sleep_duration: Vector2 = Vector2(30.0, 60.0)
@export var wander_duration: Vector2 = Vector2(6.0, 14.0)
@export var watch_duration: Vector2 = Vector2(15.0, 45.0)
@export var turn_speed: float = 5.0
@export var constrain_drag_to_room: bool = false
@export var drag_bounds: Rect2 = Rect2(-6.7, -4.1, 13.4, 8.2)

@export var base_attack: int = 1
@export var base_health: int = 1
@export var enchantment: Enchantment
@export var default_face_set: CatFaceSet = preload("res://resources/cat_faces/default.tres")

var active_face_set: CatFaceSet
var current_face: String = "neutral"
var _face_material: StandardMaterial3D
var _animation_player: AnimationPlayer
const FACE_SURFACE = 2

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var drop_indicator: MeshInstance3D = $DropIndicator

const DEFAULT_CAT_MAT = preload("res://assets/cat/elements/default_cat.tres")

enum State { IDLE, PICKED, WANDERING, WATCHING }
var ai_state = State.WANDERING
var lock_ai_state = false

var is_picked = false
var _position_before_pickup: Vector3
var _rotation_before_pickup: Vector3
var _drop_position: Vector3
var _is_dropping = false
var _behavior_time_left: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var players = $Cat.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_animation_player = players[0]
		_animation_player.animation_started.connect(_on_face_animation_started)
		_animation_player.animation_finished.connect(_on_face_animation_finished)
	set_enchantment(enchantment)
		
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	# Different starting activities and durations keep the cats out of sync.
	var starting_roll = randf()
	if starting_roll < 0.3:
		_enter_behavior(State.IDLE)
	elif starting_roll < 0.55:
		_enter_behavior(State.WATCHING)
	else:
		_enter_behavior(State.WANDERING)

func set_enchantment(e: Enchantment):
	enchantment = e
	if not is_node_ready():
		return
	if enchantment != null and enchantment.cat_material != null:
		set_body_material(enchantment.cat_material)
	else:
		# Duplicate so tinting one cat never changes another cat's material.
		var material = DEFAULT_CAT_MAT.duplicate() as StandardMaterial3D
		if enchantment != null:
			material.albedo_color = enchantment.primary_color
		set_body_material(material)
	var mesh: MeshInstance3D = $Cat/Armature/Skeleton3D/Cat
	var paw_material = mesh.mesh.surface_get_material(1).duplicate() as StandardMaterial3D
	if enchantment != null:
		paw_material.albedo_color = enchantment.primary_color
	mesh.set_surface_override_material(1, paw_material)
	set_face_set(enchantment.face_set if enchantment != null else null)

## Switch sets while preserving the expression when the new set contains it.
## Passing null restores this cat's default face set.
func set_face_set(faces: CatFaceSet) -> void:
	active_face_set = faces if faces != null else default_face_set
	if active_face_set == null:
		if is_node_ready():
			$Cat/Armature/Skeleton3D/Cat.set_surface_override_material(FACE_SURFACE, null)
		return
	if not active_face_set.has_face(current_face):
		current_face = active_face_set.default_face
	if _animation_player != null and _animation_player.is_playing():
		current_face = active_face_set.get_animation_face(_animation_player.current_animation)
	_apply_face()

func _on_face_animation_started(animation: StringName) -> void:
	if active_face_set != null:
		set_face(active_face_set.get_animation_face(String(animation)))

func _on_face_animation_finished(_animation: StringName) -> void:
	if active_face_set != null:
		set_face(active_face_set.default_face)

## Returns false for a missing texture, leaving the current expression unchanged.
func set_face(face: String) -> bool:
	if active_face_set == null:
		set_face_set(enchantment.face_set if enchantment != null else null)
	if active_face_set == null or not active_face_set.has_face(face):
		return false
	current_face = face
	_apply_face()
	return true

func _apply_face() -> void:
	if not is_node_ready() or active_face_set == null:
		return
	var mesh: MeshInstance3D = $Cat/Armature/Skeleton3D/Cat
	var texture = active_face_set.get_texture(current_face)
	if texture == null:
		mesh.set_surface_override_material(FACE_SURFACE, null)
		return
	if _face_material == null:
		# Preserve filtering, but enable alpha for the separate expression textures.
		var original = mesh.mesh.surface_get_material(FACE_SURFACE) as StandardMaterial3D
		_face_material = original.duplicate() as StandardMaterial3D
		_face_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_face_material.albedo_texture = texture
	mesh.set_surface_override_material(FACE_SURFACE, _face_material)

func set_body_material(mat: StandardMaterial3D):
	$Cat/Armature/Skeleton3D/Cat.set_surface_override_material(0, mat)

func get_cat_data() -> CatData:
	var cat_data = CatData.new()
	cat_data.cat_name = cat_name
	cat_data.base_attack = base_attack
	cat_data.base_health = base_health
	cat_data.enchantment = enchantment
	return cat_data

func _physics_process(delta: float) -> void:
	if is_picked and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_release_pickup()
	if _is_dropping:
		global_position = global_position.move_toward(_drop_position, pickup_speed * delta)
		if global_position.is_equal_approx(_drop_position):
			global_rotation = _rotation_before_pickup
			_is_dropping = false
			if not lock_ai_state:
				_choose_next_behavior()
		return

	if ai_state != State.PICKED and not lock_ai_state:
		_behavior_time_left -= delta
		if _behavior_time_left <= 0.0:
			_choose_next_behavior()

	match ai_state:
		State.IDLE:
			_process_idle(delta)
		State.WANDERING:
			_process_wander(delta)
		State.WATCHING:
			_process_watch(delta)
		State.PICKED:
			_process_picked(delta)

func _enter_behavior(next_state: State) -> void:
	ai_state = next_state
	velocity = Vector3.ZERO
	navigation_agent.set_velocity(Vector3.ZERO)
	var duration: Vector2
	match ai_state:
		State.IDLE:
			duration = sleep_duration
		State.WANDERING:
			duration = wander_duration
		State.WATCHING:
			duration = watch_duration
		_:
			return
	var minimum = maxf(0.1, minf(duration.x, duration.y))
	_behavior_time_left = randf_range(minimum, maxf(minimum, maxf(duration.x, duration.y)))

func _choose_next_behavior() -> void:
	var roll = randf()
	match ai_state:
		State.PICKED:
			# Put-down is a fresh decision, with a preference for watching or exploring.
			if roll < 0.2:
				_enter_behavior(State.IDLE)
			elif roll < 0.6:
				_enter_behavior(State.WATCHING)
			else:
				_enter_behavior(State.WANDERING)
		State.IDLE:
			# Waking cats usually observe their surroundings before exploring.
			_enter_behavior(State.WATCHING if roll < 0.75 else State.WANDERING)
		State.WANDERING:
			_enter_behavior(State.WATCHING if roll < 0.65 else State.IDLE)
		State.WATCHING:
			_enter_behavior(State.WANDERING if roll < 0.7 else State.IDLE)

func _process_idle(_delta: float) -> void:
	# Sleeping: stay still until the behavior timer wakes the cat.
	velocity = Vector3.ZERO

func _turn_toward(target: Vector3, delta: float) -> void:
	var direction = target - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	var target_yaw = atan2(-direction.x, -direction.z)
	global_rotation.y = lerp_angle(global_rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))

func _process_wander(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		find_new_wander_target()
	
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	var new_velocity: Vector3 = current_agent_position.direction_to(next_path_position) * movement_speed
	
	if new_velocity.x != 0 or new_velocity.z != 0:
		var look_target = current_agent_position + Vector3(new_velocity.x, 0, new_velocity.z)
		_turn_toward(look_target, delta)

	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

func _process_watch(delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return

	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_direction = camera.project_ray_normal(mouse_position)
	var watch_plane = Plane(Vector3.UP, global_position.y)
	var cursor_position = watch_plane.intersects_ray(ray_origin, ray_direction)
	if cursor_position == null:
		return

	var look_target: Vector3 = cursor_position
	if global_position.distance_squared_to(look_target) > 0.0001:
		_turn_toward(look_target, delta)

func _process_picked(delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	var raised_height = _position_before_pickup.y + pickup_height
	global_position.y = move_toward(global_position.y, raised_height, pickup_speed * delta)
	if camera != null:
		var mouse_position = get_viewport().get_mouse_position()
		var drag_plane = Plane(Vector3.UP, raised_height)
		var cursor_position = drag_plane.intersects_ray(
			camera.project_ray_origin(mouse_position),
			camera.project_ray_normal(mouse_position)
		)
		if cursor_position != null:
			var drag_position = _constrain_drag_position(cursor_position)
			global_position.x = drag_position.x
			global_position.z = drag_position.z
		# Look toward the lens while keeping the cat upright relative to the screen.
		var camera_direction = global_position.direction_to(camera.global_position)
		var screen_up = camera.global_basis.y.normalized()
		if not camera_direction.is_zero_approx() and absf(camera_direction.dot(screen_up)) < 0.999:
			look_at(camera.global_position, screen_up)
	drop_indicator.global_position = _get_drop_position() + Vector3.UP * 0.06

func _constrain_drag_position(at: Vector3) -> Vector3:
	if constrain_drag_to_room:
		at.x = clampf(at.x, drag_bounds.position.x, drag_bounds.end.x)
		at.z = clampf(at.z, drag_bounds.position.y, drag_bounds.end.y)
	return at

func _get_drop_position() -> Vector3:
	var target = _constrain_drag_position(global_position)
	# Beds are trigger areas rather than solid colliders, so use their placement surface.
	for bed in get_tree().get_nodes_in_group("cat_beds"):
		if bed.contains_point(target):
			target.y = bed.get_placement_position().y
			return target
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(target.x, target.y + 10.0, target.z),
		Vector3(target.x, target.y - 100.0, target.z))
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	target.y = hit.position.y if not hit.is_empty() else _position_before_pickup.y
	return target

func _begin_pickup() -> void:
	if is_picked or _is_dropping:
		return
	_position_before_pickup = global_position
	_rotation_before_pickup = global_rotation
	velocity = Vector3.ZERO
	navigation_agent.set_velocity(Vector3.ZERO)
	is_picked = true
	drop_indicator.global_position = _get_drop_position() + Vector3.UP * 0.06
	drop_indicator.visible = true
	ai_state = State.PICKED

func _release_pickup() -> void:
	drop_indicator.hide()
	_drop_position = _get_drop_position()
	is_picked = false
	_is_dropping = true

func _input(event: InputEvent) -> void:
	if is_picked and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_release_pickup()

func find_new_wander_target():
	var finding_move_target = true
	var tries = 0
	const MAX_TRIES = 5
	while finding_move_target:
		var random_offset = Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
		set_movement_target(global_position + random_offset)
		if navigation_agent.is_target_reachable():
			finding_move_target = false
			return
		
		tries+= 1
		if tries > MAX_TRIES:
			return;

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if ai_state != State.WANDERING or is_picked or _is_dropping:
		return
	velocity = safe_velocity
	move_and_slide()

func set_movement_target(target_position: Vector3) -> void:
	navigation_agent.target_position = target_position

func _on_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_begin_pickup()
		#$DangoCatSKMesh.squish()
		print(cat_name + " was clicked")
