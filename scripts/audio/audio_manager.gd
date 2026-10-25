extends Node

const MENU_TRACK = preload("res://assets/music/main_music.wav")
const BATTLE_TRACK = preload("res://assets/music/fight_music.wav")
const EFFECTS = {
	"meow": [
		preload("res://assets/misc_effects/Meow_1.wav"),
		preload("res://assets/misc_effects/Meow_2.wav"),
		preload("res://assets/misc_effects/Meow_3.wav"),
		preload("res://assets/misc_effects/Meow_4.wav"),
	],
	"purr": [preload("res://assets/misc_effects/purr_short.wav")],
	"attack": [preload("res://assets/misc_effects/attack.wav")],
	"hurt": [preload("res://assets/misc_effects/Huff.wav")],
	"huff": [preload("res://assets/misc_effects/Huff.wav")],
	"death": [preload("res://assets/misc_effects/death_meow.wav")],
	"victory": [preload("res://assets/misc_effects/victory.wav")],
	"loss": [preload("res://assets/misc_effects/loss.wav")],
}

@export var music_volume_db: float = -12.0
@export var effects_volume_db: float = -8.0
@onready var music: AudioStreamPlayer = $Music
var _music_key = ""
var _music_tween: Tween
var _effect_players: Array[AudioStreamPlayer] = []
var _last_effect_time: Dictionary = {}
var _last_variant: Dictionary = {}

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("user://title_settings.cfg") == OK:
		_set_bus_level("Master", float(config.get_value("audio", "volume", 1.0)))
		set_audio_levels(float(config.get_value("audio", "music_volume", 1.0)), float(config.get_value("audio", "effects_volume", 1.0)))
	for i in range(8):
		var player = AudioStreamPlayer.new()
		player.bus = &"Effects"
		add_child(player)
		_effect_players.append(player)

func play_menu_music() -> void:
	_play_music("menu", MENU_TRACK)

func play_battle_music() -> void:
	_play_music("battle", BATTLE_TRACK)

func _play_music(key: String, track: AudioStream) -> void:
	# This autoload survives scene changes; requesting the same track keeps its position.
	if key == _music_key and music.playing:
		return
	if _music_tween != null:
		_music_tween.kill()
	_music_key = key
	var looped = _copy_stream(track, true)
	music.stream = looped
	music.volume_db = -40.0
	music.play()
	_music_tween = create_tween()
	_music_tween.tween_property(music, "volume_db", music_volume_db, 0.5)

func play_effect(effect: String) -> void:
	if not EFFECTS.has(effect):
		return
	var now = Time.get_ticks_msec()
	# Simultaneous team attacks should sound like one hit rather than doubled audio.
	if now - _last_effect_time.get(effect, -1000) < (350 if effect == "huff" else 100):
		return
	_last_effect_time[effect] = now
	var available: AudioStreamPlayer
	for player in _effect_players:
		if not player.playing:
			available = player
			break
	if available == null:
		available = _effect_players[0]
		available.stop()
	var variants: Array = EFFECTS[effect]
	var choice = randi_range(0, variants.size() - 1)
	if variants.size() > 1 and choice == _last_variant.get(effect, -1):
		choice = (choice + randi_range(1, variants.size() - 1)) % variants.size()
	_last_variant[effect] = choice
	var stream = _copy_stream(variants[choice], false)
	available.stream = stream
	available.volume_db = effects_volume_db - (5.0 if effect == "purr" else 0.0)
	available.play()

func play_battle_result(won: bool) -> void:
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(music, "volume_db", music_volume_db - 10.0, 0.25)
	play_effect("victory" if won else "loss")

func set_audio_levels(music_level: float, effects_level: float) -> void:
	_set_bus_level("Music", music_level)
	_set_bus_level("Effects", effects_level)

func _set_bus_level(bus_name: String, level: float) -> void:
	var index = AudioServer.get_bus_index(bus_name)
	level = clampf(level, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))
	AudioServer.set_bus_mute(index, level <= 0.0)

func _copy_stream(source: AudioStream, looping: bool) -> AudioStream:
	# Keep imported resources unchanged; WAV and MP3 use different loop properties.
	var stream = source.duplicate() as AudioStream
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
		if looping:
			stream.loop_begin = 0
			stream.loop_end = roundi(source.get_length() * stream.mix_rate)
	elif stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = looping
	return stream
