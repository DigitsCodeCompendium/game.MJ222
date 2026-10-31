@tool
extends EditorNode3DGizmoPlugin

const Bone = preload("res://addons/room_maker/room_bone.gd")
const Maker = preload("res://addons/room_maker/room_maker.gd")
var undo_redo: EditorUndoRedoManager
var _drag_state: Dictionary = {}

func _init() -> void:
	create_material("wall", Color("32b85b"), false, true)
	create_material("outer", Color("ad55ba"), false, true)
	create_material("opening", Color("209ae9"), false, true)
	create_material("bar", Color("ff8c26"), false, true)
	create_handle_material("bone_handles", false, _handle_texture(Color("ff8c26")))
	create_handle_material("wall_handles", false, _handle_texture(Color("b2e83e")))
	create_handle_material("door_handles", false, _handle_texture(Color("209ae9")))

func _handle_texture(color: Color) -> Texture2D:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(16):
		for x in range(16):
			if Vector2(x - 7.5, y - 7.5).length() <= 6.5:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

func _get_gizmo_name() -> String:
	return "Room corners"

func _has_gizmo(node: Node3D) -> bool:
	return node is Bone or node is Maker

func _get_priority() -> int:
	return 1

func _v(point: Vector2) -> Vector3:
	return Vector3(point.x, 0.06, point.y)

func _loop(gizmo: EditorNode3DGizmo, polygon: PackedVector2Array, material_name: String) -> void:
	var lines = PackedVector3Array()
	for i in range(polygon.size()):
		lines.append(_v(polygon[i]))
		lines.append(_v(polygon[(i + 1) % polygon.size()]))
	gizmo.add_lines(lines, get_material(material_name, gizmo))
	gizmo.add_collision_segments(lines)

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var node = gizmo.get_node_3d()
	if node is Maker:
		for polygon in node.get_room_outlines():
			_loop(gizmo, polygon, "wall")
			for outer in Geometry2D.offset_polygon(polygon, node.wall_thickness * 0.5):
				_loop(gizmo, outer, "outer")
		return
	var room = node
	if room.kind == 0:
		var outline: PackedVector2Array = room.outline()
		_loop(gizmo, outline, "wall")
		var handles = PackedVector3Array()
		for point in outline:
			handles.append(_v(point))
		gizmo.add_handles(handles, get_material("wall_handles", gizmo), PackedInt32Array([0, 1, 2, 3]))
		var middle: Vector2 = room.center()
		var bar = PackedVector3Array()
		for offset in [-0.06, -0.03, 0.0, 0.03, 0.06]:
			bar.append(_v(middle + Vector2(-0.35, offset)))
			bar.append(_v(middle + Vector2(0.35, offset)))
		gizmo.add_lines(bar, get_material("bar", gizmo))
		gizmo.add_handles(PackedVector3Array([_v(middle)]), get_material("bone_handles", gizmo), PackedInt32Array([4]))
	else:
		var middle: Vector2 = (room.start + room.end) * 0.5
		var lines = PackedVector3Array([_v(room.start), _v(room.end)])
		gizmo.add_lines(lines, get_material("opening", gizmo))
		gizmo.add_collision_segments(lines)
		gizmo.add_handles(PackedVector3Array([_v(room.start), _v(room.end), _v(middle)]),
			get_material("door_handles", gizmo), PackedInt32Array([0, 1, 2]))

func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, _secondary: bool) -> String:
	if gizmo.get_node_3d().kind == 0:
		return ["Corner A", "Corner B", "Corner C", "Corner D", "Move room"][handle_id]
	return ["Opening start", "Opening end", "Move opening"][handle_id]

func _get_handle_value(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> Variant:
	_drag_state = gizmo.get_node_3d().edit_state()
	return _drag_state.duplicate()

func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, _secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var bone = gizmo.get_node_3d()
	var plane = Plane(bone.global_basis.y.normalized(), bone.global_position)
	var hit = plane.intersects_ray(camera.project_ray_origin(screen_pos), camera.project_ray_normal(screen_pos))
	if hit == null:
		return
	var local: Vector3 = bone.to_local(hit)
	var point = Vector2(local.x, local.z).snapped(Vector2.ONE * 0.25)
	if bone.kind == 0:
		bone.restore_state(_drag_state)
		if handle_id < 4:
			bone.move_corner(handle_id, point)
		else:
			var middle: Vector2 = (_drag_state.corners[0] + _drag_state.corners[2]) * 0.5
			bone.translate_room(point - middle, _drag_state.corners)
	elif handle_id == 0:
		bone.start = point
	elif handle_id == 1:
		bone.end = point
	else:
		var middle: Vector2 = (_drag_state.start + _drag_state.end) * 0.5
		bone.start = _drag_state.start + point - middle
		bone.end = _drag_state.end + point - middle

func _commit_handle(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool, restore: Variant, cancel: bool) -> void:
	var bone = gizmo.get_node_3d()
	if cancel:
		bone.restore_state(restore)
		return
	undo_redo.create_action("Edit room corners")
	undo_redo.add_do_method(bone, "restore_state", bone.edit_state())
	undo_redo.add_undo_method(bone, "restore_state", restore)
	undo_redo.commit_action()
