extends Node3D

const SETTINGS_PATH = "user://title_settings.cfg"

@onready var camera: Camera3D = $Camera3D
@onready var cat: Cat = $MenuCat
@onready var beds: Array[Node] = $Beds.get_children()
var hovered_bed = -1
var overlay: PanelContainer
@onready var credits_panel: PanelContainer = $MenuUI/Interface/CreditsPanel
@onready var settings_panel: PanelContainer = $MenuUI/Interface/SettingsPanel
@onready var volume_slider: HSlider = $MenuUI/Interface/SettingsPanel/Content/Volume
@onready var fullscreen_toggle: CheckButton = $MenuUI/Interface/SettingsPanel/Content/Fullscreen
var volume = 1.0
var fullscreen = false

func _ready() -> void:
	get_viewport().size_changed.connect(_resize_background)
	_resize_background()
	credits_panel.hide()
	settings_panel.hide()
	overlay = credits_panel
	for index in range(beds.size()):
		beds[index].cat_placed.connect(func(_cat): _select_bed(index))
	credits_panel.get_node("Content/Back").pressed.connect(_close_panel)
	settings_panel.get_node("Content/Back").pressed.connect(_close_panel)
	_load_settings()
	volume_slider.set_value_no_signal(volume)
	fullscreen_toggle.set_pressed_no_signal(fullscreen)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

func _resize_background() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size.y <= 0.0:
		return
	var quad: QuadMesh = $Camera3D/TitleBackground.mesh
	var texture: Texture2D = quad.material.albedo_texture
	var image_aspect = float(texture.get_width()) / texture.get_height()
	var view_aspect = viewport_size.x / viewport_size.y
	var view_size = Vector2(camera.size * view_aspect, camera.size)
	if camera.keep_aspect == Camera3D.KEEP_WIDTH:
		view_size = Vector2(camera.size, camera.size / view_aspect)
	var height = maxf(view_size.y, view_size.x / image_aspect)
	quad.size = Vector2(height * image_aspect, height)

func _on_volume_changed(value: float) -> void:
	volume = value
	_apply_settings()
	_save_settings()

func _on_fullscreen_toggled(enabled: bool) -> void:
	fullscreen = enabled
	_apply_settings()
	_save_settings()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and overlay.visible:
		_close_panel()
		get_viewport().set_input_as_handled()
		return
	if overlay.visible:
		return
func _physics_process(_delta: float) -> void:
	_set_hover(_bed_at(cat.position) if cat.is_picked else -1)

func _bed_at(at: Vector3) -> int:
	for index in range(beds.size()):
		if beds[index].contains_point(to_global(at)):
			return index
	return -1

func _set_hover(index: int) -> void:
	hovered_bed = index
	for bed_index in range(beds.size()):
		beds[bed_index].set_highlighted(bed_index == index)

func _select_bed(index: int) -> void:
	cat.set_process_input(false)
	cat.input_ray_pickable = false
	
	match index:
		0:
			GameManager.start_new_game()
		1, 2:
			overlay.hide()
			overlay = credits_panel if index == 1 else settings_panel
			overlay.show()
			overlay.get_node("Content/Back").grab_focus()

func _close_panel() -> void:
	overlay.hide()
	cat.set_process_input(true)
	cat.input_ray_pickable = true

func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, volume <= 0.0)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		volume = clampf(float(config.get_value("audio", "volume", 1.0)), 0.0, 1.0)
		fullscreen = bool(config.get_value("display", "fullscreen", false))
	_apply_settings()

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)
