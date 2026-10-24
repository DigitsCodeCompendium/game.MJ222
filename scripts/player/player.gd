extends Node3D

@export var move_speed = 10
@export var rotate_speed = 0.02

@onready var camera = $Camera3D

var _rotation_input: Vector2

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	var velocity = Vector3.ZERO
	
	if Input.is_action_pressed("move_left"):
		velocity += Vector3(-1, 0, 0)
	if Input.is_action_pressed("move_right"):
		velocity += Vector3(1, 0, 0)
	if Input.is_action_pressed("move_up"):
		velocity += Vector3(0, 0, -1)
	if Input.is_action_pressed("move_down"):
		velocity += Vector3(0, 0, 1)
	
	var basis = Basis(Vector3.UP, rotation.y)
	
	position += basis * velocity * move_speed * delta
	
	if Input.is_action_pressed("rotate") or Input.is_action_just_released("rotate"):
		# For the rotation vector, x is pitch, y is yaw
		rotation.x = clamp(rotation.x - _rotation_input.y * rotate_speed, -PI*1/3, -PI*1/6)
		rotation.y -= _rotation_input.x * rotate_speed
		_rotation_input = Vector2.ZERO

func _input(event):
	if Input.is_action_pressed("rotate") and event is InputEventMouseMotion:
		var mouse_event = event as InputEventMouseMotion
		_rotation_input += mouse_event.screen_relative
