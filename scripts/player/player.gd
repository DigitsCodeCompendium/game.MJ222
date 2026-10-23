extends Node3D

const speed = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
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
	
	position += velocity * speed * delta
	
	
	pass
