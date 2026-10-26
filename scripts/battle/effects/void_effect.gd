extends Node3D

func _ready():
	$Particles.emitting = true

func get_duration():
	return $Particles.lifetime
