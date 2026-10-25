class_name PrepAreaDoor
extends CollisionObject3D

signal on_clicked;

@export var disabled: bool

func _ready():
	input_event.connect(_on_input_event)

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int):
	if disabled:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		on_clicked.emit()
