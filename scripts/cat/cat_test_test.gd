extends Node3D

@onready var cat: Cat = $Cat
@onready var pivot: Node3D = $OrbitPivot
@onready var camera: Camera3D = $OrbitPivot/Camera3D
@onready var enchantments: OptionButton = $UI/Panel/Controls/Enchantment
@onready var animations: OptionButton = $UI/Panel/Controls/Animation
@onready var repeat: CheckButton = $UI/Panel/Controls/Loop

var _enchantments: Array[Enchantment] = []
var _animations: PackedStringArray = []
var _player: AnimationPlayer
var _orbiting = false

func _ready() -> void:
	# Keep the normal cat's appearance API, but disable wandering and picking up.
	cat.set_physics_process(false)
	cat.set_process_input(false)
	cat.input_ray_pickable = false
	enchantments.add_item("None / default")
	for enchantment in EnchantmentLibrary.all_enchantments:
		if enchantment != null:
			_enchantments.append(enchantment)
	_enchantments.sort_custom(func(a, b): return a.display_name.naturalnocasecmp_to(b.display_name) < 0)
	for enchantment in _enchantments:
		enchantments.add_item(enchantment.display_name)
	enchantments.item_selected.connect(_select_enchantment)
	animations.item_selected.connect(_select_animation)
	repeat.toggled.connect(_on_loop_toggled)
	$UI/Panel/Controls/ResetCamera.pressed.connect(_reset_camera)
	cat.model_changed.connect(_refresh_animations)
	_refresh_animations()
	_reset_camera()

func _refresh_animations() -> void:
	var previous_animation = ""
	if animations.selected > 0 and animations.selected <= _animations.size():
		previous_animation = _animations[animations.selected - 1]
	if is_instance_valid(_player) and _player.animation_finished.is_connected(_on_animation_finished):
		_player.animation_finished.disconnect(_on_animation_finished)
	_player = cat._animation_player
	_animations.clear()
	animations.clear()
	animations.add_item("None / rest pose")
	if _player != null:
		_player.animation_finished.connect(_on_animation_finished)
		for animation in _player.get_animation_list():
			if animation != "RESET":
				_animations.append(animation)
				animations.add_item(animation)
	animations.disabled = _animations.is_empty()
	var previous_index = _animations.find(previous_animation)
	if previous_index >= 0:
		animations.select(previous_index + 1)
		_select_animation(previous_index + 1)

func _select_enchantment(index: int) -> void:
	cat.set_enchantment(null if index == 0 else _enchantments[index - 1])

func _select_animation(index: int) -> void:
	if _player == null:
		return
	_player.stop()
	if index == 0:
		if _player.has_animation("RESET"):
			_player.play("RESET")
			_player.advance(0)
			_player.stop()
		if cat.active_face_set != null:
			cat.set_face(cat.active_face_set.default_face)
	else:
		_player.play(_animations[index - 1])

func _on_animation_finished(animation: StringName) -> void:
	if repeat.button_pressed and animations.selected > 0 and animation == _animations[animations.selected - 1]:
		_player.play(animation)

func _on_loop_toggled(enabled: bool) -> void:
	if enabled and animations.selected > 0:
		_select_animation(animations.selected)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z = maxf(2.5, camera.position.z - 0.5)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z = minf(15.0, camera.position.z + 0.5)
	elif event is InputEventMouseMotion and _orbiting:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_orbiting = false
			return
		pivot.rotation.y -= event.relative.x * 0.008
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * 0.008, deg_to_rad(-75), deg_to_rad(35))

func _reset_camera() -> void:
	pivot.rotation_degrees = Vector3(-15, 0, 0)
	camera.position.z = 6.5
