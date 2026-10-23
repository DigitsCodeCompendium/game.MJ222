extends CharacterBody3D

@export var cat_name = "default_cat"
@export var movement_speed: float = 4.0

@export var enchantment: Enchantment

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

enum State { IDLE, PICKED, WANDERING, WATCHING }
var ai_state = State.WATCHING

var is_picked = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if enchantment != null:
		# Ok this is probably an awful way to do this, just using it as a hack to test things out for now
		var mesh = $DangoCatSKMesh/Armature/Skeleton3D/Cube_004.mesh as ArrayMesh
		var material = mesh.surface_get_material(0) as StandardMaterial3D
		material = material.duplicate()
		material.albedo_color = enchantment.primary_color
		$DangoCatSKMesh/Armature/Skeleton3D/Cube_004.set_surface_override_material(0, material)
		
	navigation_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(delta: float) -> void:
	match ai_state:
		State.IDLE:
			_process_idle(delta)
		State.WANDERING:
			_process_wander(delta)
		State.WATCHING:
			_process_watch(delta)

func _process_idle(delta: float) -> void:
	pass

func _process_wander(_delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		find_new_wander_target()
	
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	var new_velocity: Vector3 = current_agent_position.direction_to(next_path_position) * movement_speed
	
	if new_velocity.x != 0 or new_velocity.z != 0:
		var look_target = current_agent_position + Vector3(new_velocity.x, 0, new_velocity.z)
		look_at(look_target, Vector3.UP)

	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

func _process_watch(_delta: float) -> void:
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
		look_at(look_target, Vector3.UP)

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
	velocity = safe_velocity
	move_and_slide()

func set_movement_target(target_position: Vector3) -> void:
	navigation_agent.target_position = target_position

func _on_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		$DangoCatSKMesh.squish()
		print(cat_name + " was clicked")
