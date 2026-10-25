class_name Cat
extends CharacterBody3D

@export var cat_name = "Squeeb"
@export var movement_speed: float = 4.0
@export var pickup_height: float = 2.0
@export var pickup_speed: float = 6.0
@export var idle_duration: Vector2 = Vector2(3.0, 8.0)
@export var sleep_duration: Vector2 = Vector2(30.0, 60.0)
@export var animate_ai: bool = true
@export var animation_blend_time: float = 0.15
@export var wander_duration: Vector2 = Vector2(6.0, 14.0)
@export var watch_duration: Vector2 = Vector2(15.0, 45.0)
@export var turn_speed: float = 5.0
@export var constrain_drag_to_room: bool = false
@export var drag_bounds: Rect2 = Rect2(-6.7, -4.1, 13.4, 8.2)

@export var attack_offset: int = 0
@export var health_offset: int = 0
@export var enchantment: Enchantment
@onready var visual: CatVisual = $CatVisual

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var drop_indicator: MeshInstance3D = $DropIndicator

enum State { IDLE, PICKED, WANDERING, WATCHING, SLEEPING }
var ai_state = State.WANDERING
var lock_ai_state = false

var is_picked = false
var _position_before_pickup: Vector3
var _rotation_before_pickup: Vector3
var _drop_position: Vector3
var _is_dropping = false
var _behavior_time_left: float = 0.0
var _wander_has_target = false
var _resume_wander_after_idle = false
var _lookaround_time_left = 0.0
var _lookaround_yaw = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_enchantment(enchantment)
		
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	# Different starting activities and durations keep the cats out of sync.
	var starting_roll = randf()
	if starting_roll < 0.2:
		_enter_behavior(State.SLEEPING)
	elif starting_roll < 0.35:
		_enter_behavior(State.IDLE)
	elif starting_roll < 0.6:
		_enter_behavior(State.WATCHING)
	else:
		_enter_behavior(State.WANDERING)

func set_enchantment(e: Enchantment) -> void:
	enchantment = e
	if is_node_ready():
		visual.set_enchantment(e)
		if animate_ai:
			_sync_state_animation()

func _sync_state_animation() -> void:
	if not animate_ai:
		visual.stop_animation()
		return
	visual.animation_blend_time = animation_blend_time
	var state_name: String = State.keys()[ai_state].to_lower()
	var animations = {"idle": "Idle", "wandering": "Walk", "watching": "Idle", "picked": "Idle", "sleeping": "Sleep"}
	visual.play_behavior(state_name, animations[state_name])

func get_cat_data() -> CatData:
	var cat_data = CatData.new()
	cat_data.cat_name = cat_name
	cat_data.attack_offset = attack_offset
	cat_data.health_offset = health_offset
	cat_data.enchantment = enchantment
	return cat_data

func _physics_process(delta: float) -> void:
	_sync_state_animation()
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
		State.SLEEPING:
			velocity = Vector3.ZERO
		State.WANDERING:
			_process_wander(delta)
		State.WATCHING:
			_process_watch(delta)
		State.PICKED:
			_process_picked(delta)

func _enter_behavior(next_state: State) -> void:
	ai_state = next_state
	_resume_wander_after_idle = false
	if next_state == State.WANDERING:
		_wander_has_target = false
	elif next_state == State.IDLE:
		_lookaround_time_left = randf_range(0.6, 1.2)
		_lookaround_yaw = global_rotation.y
	_sync_state_animation()
	velocity = Vector3.ZERO
	navigation_agent.set_velocity(Vector3.ZERO)
	var duration: Vector2
	match ai_state:
		State.IDLE:
			duration = idle_duration
		State.SLEEPING:
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
	if ai_state == State.IDLE and _resume_wander_after_idle:
		_enter_behavior(State.WANDERING)
		return
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
			if roll < 0.25:
				_enter_behavior(State.SLEEPING)
			else:
				_enter_behavior(State.WATCHING if roll < 0.65 else State.WANDERING)
		State.SLEEPING:
			# Waking cats usually observe their surroundings before exploring.
			_enter_behavior(State.WATCHING if roll < 0.8 else State.WANDERING)
		State.WANDERING:
			_pause_after_wander()
		State.WATCHING:
			if roll < 0.2:
				_enter_behavior(State.SLEEPING)
			else:
				_enter_behavior(State.WANDERING if roll < 0.75 else State.IDLE)

func _pause_after_wander() -> void:
	_enter_behavior(State.IDLE)
	_resume_wander_after_idle = true

func _process_idle(delta: float) -> void:
	velocity = Vector3.ZERO
	_lookaround_time_left -= delta
	if _lookaround_time_left <= 0.0:
		_lookaround_yaw = global_rotation.y + randf_range(-1.2, 1.2)
		_lookaround_time_left = randf_range(0.8, 1.8)
	global_rotation.y = lerp_angle(global_rotation.y, _lookaround_yaw, 1.0 - exp(-turn_speed * 0.6 * delta))

func _turn_toward(target: Vector3, delta: float) -> void:
	var direction = target - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	var target_yaw = atan2(-direction.x, -direction.z)
	global_rotation.y = lerp_angle(global_rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))

func _process_wander(delta: float) -> void:
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if not _wander_has_target:
		if not find_new_wander_target():
			_pause_after_wander()
			return
	
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		navigation_agent.set_velocity(Vector3.ZERO)
		if not lock_ai_state:
			_pause_after_wander()
		return
	
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
		if not bed.prevent_insertion and bed.contains_point(target):
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
	AudioManager.play_effect("meow")
	drop_indicator.global_position = _get_drop_position() + Vector3.UP * 0.06
	drop_indicator.visible = true
	ai_state = State.PICKED
	_sync_state_animation()

func _release_pickup() -> void:
	drop_indicator.hide()
	_drop_position = _get_drop_position()
	is_picked = false
	_is_dropping = true

func _input(event: InputEvent) -> void:
	if is_picked and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_release_pickup()

func find_new_wander_target() -> bool:
	var map = navigation_agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return false
	for attempt in range(6):
		var target = NavigationServer3D.map_get_random_point(map, navigation_agent.navigation_layers, true)
		var horizontal_offset = target - global_position
		horizontal_offset.y = 0.0
		if horizontal_offset.length_squared() < 2.25:
			continue
		var path = NavigationServer3D.map_get_path(map, global_position, target, true, navigation_agent.navigation_layers)
		if path.is_empty() or path[path.size() - 1].distance_to(target) > navigation_agent.target_desired_distance:
			continue
		set_movement_target(target)
		_wander_has_target = true
		return true
	return false

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
