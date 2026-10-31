@tool
extends Node3D

func _ready() -> void:
	_bind_lighting.call_deferred()

func _bind_lighting() -> void:
	var lighting = owner.get_node_or_null("RoomLighting") if owner != null else null
	if lighting == null:
		lighting = get_tree().get_first_node_in_group("room_lighting")
	if lighting == null:
		return
	if not lighting.theme_changed.is_connected(_apply_theme):
		lighting.theme_changed.connect(_apply_theme)
	_apply_theme(lighting.theme)

func _apply_theme(theme: int) -> void:
	var night = theme == 1
	$WarmLight.visible = night
	$PoolLight.visible = night
	var material: StandardMaterial3D = $Bulb.mesh.material
	material.emission_energy_multiplier = 1.8 if night else 0.0
	var shade: StandardMaterial3D = $Shade.mesh.material
	shade.emission_energy_multiplier = 0.28 if night else 0.0
