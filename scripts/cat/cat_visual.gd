## Shared presentation only: no navigation, pickup, stats, or combat rules.
class_name CatVisual
extends Node3D

signal model_changed
@export var enchantment: Enchantment
@export var default_face_set: CatFaceSet = preload("res://resources/cat_faces/default.tres")
@export var animation_blend_time: float = 0.15
var active_face_set: CatFaceSet
var current_face: String = "neutral"
var animation_player: AnimationPlayer
var _face_material: StandardMaterial3D
var _model: Node3D
var _model_scene: PackedScene
var _loop_animation = ""
const DEFAULT_MODEL = preload("res://scenes/cat/models/base_cat_model.tscn")
const DEFAULT_CAT_MAT = preload("res://assets/cat/elements/default_cat.tres")

func _ready() -> void:
	set_enchantment(enchantment)

func _process(_delta: float) -> void:
	_resume_animation()

func set_enchantment(e: Enchantment):
	enchantment = e
	if not is_node_ready():
		return
	var changed_model = _set_model_scene(enchantment.cat_scene if enchantment != null and enchantment.cat_scene != null else DEFAULT_MODEL)
	if enchantment != null and enchantment.cat_material != null:
		set_body_material(enchantment.cat_material)
	else:
		# Duplicate so tinting one cat never changes another cat's material.
		var material = DEFAULT_CAT_MAT.duplicate() as StandardMaterial3D
		if enchantment != null:
			material.albedo_color = enchantment.primary_color
		set_body_material(material)
	var mesh = _surface_mesh("paw")
	if mesh != null:
		var original = mesh.mesh.surface_get_material(_surface_index("paw"))
		var paw_material = original.duplicate() as StandardMaterial3D if original is StandardMaterial3D else StandardMaterial3D.new()
		if enchantment != null:
			paw_material.albedo_color = enchantment.primary_color
		mesh.set_surface_override_material(_surface_index("paw"), paw_material)
	set_face_set(enchantment.face_set if enchantment != null else null)

	if changed_model:
		_resume_animation()
		model_changed.emit()

func _find_animation(requested: String) -> StringName:
	if animation_player == null:
		return &""
	if animation_player.has_animation(requested):
		return StringName(requested)
	for animation in animation_player.get_animation_list():
		if animation.get_slice("|", animation.get_slice_count("|") - 1).to_lower() == requested.to_lower():
			return animation
	return &""

func _resume_animation() -> void:
	if not _loop_animation.is_empty():
		_play_animation(_loop_animation)

func _play_animation(requested: String) -> StringName:
	var animation = _find_animation(requested)
	if not animation.is_empty() and (animation_player.current_animation != animation or not animation_player.is_playing()):
		animation_player.play(animation, animation_blend_time)
	return animation

func play_loop(requested: String) -> void:
	_loop_animation = requested
	_resume_animation()

func stop_animation() -> void:
	_loop_animation = ""
	if animation_player != null:
		animation_player.stop()

func play_once(requested: String) -> void:
	_loop_animation = ""
	var animation = _play_animation(requested)
	if animation.is_empty():
		return
	var duration = animation_player.get_animation(animation).length / maxf(absf(animation_player.speed_scale), 0.01)
	await get_tree().create_timer(maxf(duration, 0.01), false).timeout
	if animation_player != null:
		animation_player.pause()

func play_behavior(state: String, fallback: String) -> void:
	var requested = fallback
	if _model is CatModel:
		requested = _model.ai_animations.get(state, fallback)
	if _find_animation(requested).is_empty():
		requested = "Idle"
	play_loop(requested)

func _set_model_scene(scene: PackedScene) -> bool:
	var existing = get_node_or_null("Cat") as Node3D
	if _model == existing and _model != null and _model_scene == scene:
		return false
	if existing == null or existing.scene_file_path != scene.resource_path or (_model_scene != null and _model_scene != scene):
		var instance = scene.instantiate()
		if not instance is Node3D or instance is CollisionObject3D:
			push_error("Enchantment cat_scene must be a visual Node3D scene, not a gameplay Cat scene.")
			instance.free()
			return false
		if existing != null:
			remove_child(existing)
			_retire_model(existing)
		instance.name = "Cat"
		add_child(instance)
		_model = instance
	else:
		_model = existing
	_model_scene = scene
	_face_material = null
	animation_player = null
	var players = _model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		animation_player = players[0]
		animation_player.animation_started.connect(_on_face_animation_started)
		animation_player.animation_finished.connect(_on_face_animation_finished)
	return true

func _surface_index(part: String) -> int:
	if _model is CatModel:
		return _model.get(part + "_surface")
	return {"body": 0, "paw": 1, "face": 2}[part]

func _surface_mesh(part: String) -> MeshInstance3D:
	if _model is CatModel:
		return _model.get_surface_mesh(part)
	if _model == null:
		return null
	var meshes = _model.find_children("*", "MeshInstance3D", true, false)
	if _model is MeshInstance3D:
		meshes.push_front(_model)
	for mesh in meshes:
		if mesh.mesh != null and mesh.mesh.get_surface_count() > _surface_index(part):
			return mesh
	return null

## Switch sets while preserving the expression when the new set contains it.
## Passing null restores this cat's default face set.
func set_face_set(faces: CatFaceSet) -> void:
	active_face_set = faces if faces != null else default_face_set
	if active_face_set == null:
		if is_node_ready():
			var mesh = _surface_mesh("face")
			if mesh != null:
				mesh.set_surface_override_material(_surface_index("face"), null)
		return
	if not active_face_set.has_face(current_face):
		current_face = active_face_set.default_face
	if animation_player != null and animation_player.is_playing():
		current_face = active_face_set.get_animation_face(animation_player.current_animation)
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
	var mesh = _surface_mesh("face")
	if mesh == null:
		return
	var texture = active_face_set.get_texture(current_face)
	if texture == null:
		mesh.set_surface_override_material(_surface_index("face"), null)
		return
	if _face_material == null:
		# Preserve filtering, but enable alpha for the separate expression textures.
		var original = mesh.mesh.surface_get_material(_surface_index("face")) as StandardMaterial3D
		_face_material = original.duplicate() as StandardMaterial3D if original != null else StandardMaterial3D.new()
		_face_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_face_material.albedo_texture = texture
	mesh.set_surface_override_material(_surface_index("face"), _face_material)

func set_body_material(mat: Material):
	var mesh = _surface_mesh("body")
	if mesh != null:
		mesh.set_surface_override_material(_surface_index("body"), mat)

func _retire_model(model: Node3D) -> void:
	# Allow queued renderer updates to finish before releasing its materials.
	if DisplayServer.get_name() == "headless":
		get_tree().process_frame.connect(model.queue_free, CONNECT_ONE_SHOT)
	else:
		RenderingServer.frame_post_draw.connect(model.queue_free, CONNECT_ONE_SHOT)
