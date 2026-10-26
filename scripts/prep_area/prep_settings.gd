extends CanvasLayer

const SETTINGS_PATH = "user://title_settings.cfg"
@onready var overlay: Control = $Overlay
@onready var content: VBoxContainer = $Overlay/Center/Panel/Content
var _owns_pause = false
var _ending_run = false

func _ready() -> void:
	overlay.hide()
	for control_name in ["Master", "Music", "Effects"]:
		content.get_node(control_name).value_changed.connect(_save_settings)
	content.get_node("Fullscreen").toggled.connect(_save_settings)
	content.get_node("Back").pressed.connect(close)
	content.get_node("EndRun").pressed.connect(_end_run)

func _on_cat_placed(_cat: Node3D) -> void:
	open.call_deferred()

func open() -> void:
	if overlay.visible or _ending_run:
		return
	for bus_name in ["Master", "Music", "Effects"]:
		var index = AudioServer.get_bus_index(bus_name)
		var level = 0.0 if AudioServer.is_bus_mute(index) else db_to_linear(AudioServer.get_bus_volume_db(index))
		content.get_node(bus_name).set_value_no_signal(level)
	content.get_node("Fullscreen").set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	overlay.show()
	_owns_pause = not get_tree().paused
	get_tree().paused = true
	content.get_node("Back").grab_focus()

func close() -> void:
	if _ending_run:
		return
	overlay.hide()
	_resume()

func _input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _save_settings(_value: Variant) -> void:
	var master: float = content.get_node("Master").value
	var music: float = content.get_node("Music").value
	var effects: float = content.get_node("Effects").value
	var fullscreen: bool = content.get_node("Fullscreen").button_pressed
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master, 0.0001)))
	AudioServer.set_bus_mute(0, master <= 0.0)
	AudioManager.set_audio_levels(music, effects)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "volume", master)
	config.set_value("audio", "music_volume", music)
	config.set_value("audio", "effects_volume", effects)
	config.set_value("display", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)

func _end_run() -> void:
	if _ending_run:
		return
	_ending_run = true
	content.get_node("EndRun").disabled = true
	content.get_node("Back").disabled = true
	_resume()
	GameManager.end_run()

func _resume() -> void:
	if _owns_pause:
		get_tree().paused = false
		_owns_pause = false

func _exit_tree() -> void:
	_resume()
