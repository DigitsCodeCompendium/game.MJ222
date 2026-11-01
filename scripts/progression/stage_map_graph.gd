extends Control

@export var interactive: bool = false
var _positions: Dictionary = {}

func _ready() -> void:
	GameManager.progress_changed.connect(queue_redraw)
	resized.connect(queue_redraw)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW

func _draw() -> void:
	_positions.clear()
	var route = GameManager.route
	var font = ThemeDB.fallback_font
	var columns = route.layers.size()
	if columns == 0:
		return
	for column in range(columns):
		var layer = route.layers[column]
		for lane in range(layer.size()):
			_positions[layer[lane]] = Vector2(65 + (size.x - 130) * column / maxf(1, columns - 1), 36 + (size.y - 110) * route.lane_position(lane, layer.size()))
	for id in route.nodes:
		for next in route.nodes[id].next:
			var traversed = id in route.completed and next in route.visited
			var available = id == route.current_id and route.can_choose(next)
			var color = Color("689278") if traversed else (Color("c18a36") if available else Color("c5b799"))
			draw_line(_positions[id], _positions[next], color, 4.0 if traversed or available else 2.0, true)
	for id in route.nodes:
		var position: Vector2 = _positions[id]
		var current = id == route.current_id
		var cleared = id in route.completed
		var available = route.can_choose(id)
		var color = Color("8eada1") if cleared else (Color("edc96b") if current else (Color("f0dcb0") if available else Color("d7c9b1")))
		draw_circle(position, 24 if current else 20, Color("76583e"), true, -1, true)
		draw_circle(position, 20 if current else 16, color, true, -1, true)
		if available:
			draw_arc(position, 26, 0, TAU, 40, Color("b77b2e"), 2.0, true)
		var title: String = route.nodes[id].title
		var width = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string(font, position + Vector2(-width / 2, 45), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("493b2c"))
		var count = route.LEVELS_PER_STAGE if cleared else (route.level if current else 0)
		for i in range(route.LEVELS_PER_STAGE):
			draw_circle(position + Vector2((i - 2.5) * 10, 60), 3.0, Color("54846b") if i < count else Color("b6a88d"), true, -1, true)
		var mark = "OK" if cleared else (str(int(route.nodes[id].depth) + 1))
		draw_string(font, position + Vector2(-font.get_string_size(mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x / 2, 6), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("493b2c"))

func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for id in _positions:
			if event.position.distance_to(_positions[id]) < 34:
				if GameManager.choose_next_stage(id):
					accept_event()
				return

func _get_tooltip(at_position: Vector2) -> String:
	for id in _positions:
		if at_position.distance_to(_positions[id]) < 34:
			var route = GameManager.route
			var status = "Click to travel here" if route.can_choose(id) else ("Current stage" if id == route.current_id else ("Cleared" if id in route.completed else "Not reachable yet"))
			return "%s\nSix levels\n%s" % [route.nodes[id].title, status]
	return ""
