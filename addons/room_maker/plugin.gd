@tool
extends EditorPlugin

const Bone = preload("res://addons/room_maker/room_bone.gd")
const Maker = preload("res://addons/room_maker/room_maker.gd")
const Gizmo = preload("res://addons/room_maker/room_gizmo.gd")
var _gizmo: EditorNode3DGizmoPlugin
var _tools: HBoxContainer
var _selected: Node3D

func _enter_tree() -> void:
	add_custom_type("RoomMaker", "Node3D", Maker, get_editor_interface().get_base_control().get_theme_icon("CSGPolygon3D", "EditorIcons"))
	add_custom_type("RoomRectangle", "Node3D", Bone, get_editor_interface().get_base_control().get_theme_icon("CSGBox3D", "EditorIcons"))
	_gizmo = Gizmo.new()
	_gizmo.undo_redo = get_undo_redo()
	add_node_3d_gizmo_plugin(_gizmo)
	_tools = HBoxContainer.new()
	for entry in [["Add extension", 0], ["Add room", 1], ["Add opening", 2]]:
		var button = Button.new()
		button.text = entry[0]
		button.pressed.connect(_add_bone.bind(entry[1]))
		_tools.add_child(button)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _tools)
	_tools.hide()
	get_editor_interface().get_selection().selection_changed.connect(_selection_changed)

func _exit_tree() -> void:
	get_editor_interface().get_selection().selection_changed.disconnect(_selection_changed)
	remove_node_3d_gizmo_plugin(_gizmo)
	remove_custom_type("RoomMaker")
	remove_custom_type("RoomRectangle")
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _tools)
	_tools.queue_free()

func _selection_changed() -> void:
	_selected = null
	var selected = get_editor_interface().get_selection().get_selected_nodes()
	if selected.size() == 1 and (selected[0] is Bone or selected[0] is Maker):
		_selected = selected[0]
	_tools.visible = _selected != null

func _add_bone(mode: int) -> void:
	if not is_instance_valid(_selected):
		return
	var bone = Bone.new()
	bone.name = "Opening" if mode == 2 else "Room"
	bone.kind = 1 if mode == 2 else 0
	var maker = _selected if _selected is Maker else _selected.get_maker()
	var parent = _selected
	if mode == 2:
		bone.start = Vector2(-1, 0)
		bone.end = Vector2(1, 0)
	else:
		bone.corners = PackedVector2Array([Vector2(-3,-3), Vector2(3,-3), Vector2(3,3), Vector2(-3,3)])
	if _selected is Bone:
		bone.room_id = _selected.room_id
		if _selected.kind == 0:
			var points: PackedVector2Array = _selected.outline()
			var edge_center = (points[1] + points[2]) * 0.5
			if mode == 2:
				var side = (points[2] - points[1]).normalized()
				bone.start = edge_center - side
				bone.end = edge_center + side
			else:
				var outward = (points[1] - points[0]).normalized() * 6.0
				bone.corners = PackedVector2Array([points[1], points[1] + outward, points[2] + outward, points[2]])
	if mode == 1:
		bone.room_id = StringName("room_%d" % (maker.get_bones().size() + 1))
	var undo = get_undo_redo()
	undo.create_action("Add room opening" if mode == 2 else "Add rectangular room")
	undo.add_do_method(parent, "add_child", bone, true)
	undo.add_do_method(bone, "set_owner", get_editor_interface().get_edited_scene_root())
	undo.add_do_method(maker, "queue_rebuild")
	undo.add_undo_method(parent, "remove_child", bone)
	undo.add_undo_method(maker, "queue_rebuild")
	undo.add_do_reference(bone)
	undo.commit_action()
	get_editor_interface().get_selection().clear()
	get_editor_interface().get_selection().add_node(bone)
