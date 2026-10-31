@tool
extends Node3D

## Geometry is built only by the window's parent controller.
func rebuild(settings: Dictionary) -> Dictionary:
	for previous in get_children():
		remove_child(previous)
		previous.queue_free()
	var width = settings["width"]
	var height = settings["height"]
	var frame_thickness = settings["frame_thickness"]
	var depth = settings["depth"]
	var columns = settings["columns"]
	var rows = settings["rows"]
	var divider_width = settings["divider_width"]
	var sill_depth = settings["sill_depth"]
	var frame_color = settings["frame_color"]
	var trim_color = settings["trim_color"]
	var glass_color = settings["glass_color"]
	var show_sill = settings["show_sill"]
	var w = maxf(width, 0.6)
	var h = maxf(height, 0.6)
	var frame = clampf(frame_thickness, 0.02, minf(w, h) * 0.25)
	var opening = Vector2(w - frame * 2.0, h - frame * 2.0)
	var column_count = maxi(columns, 1)
	var row_count = maxi(rows, 1)
	var divider = clampf(divider_width, 0.01, minf(opening.x / column_count, opening.y / row_count) * 0.4)
	var wood = _material(frame_color)
	var trim = _material(trim_color)
	_box("LeftFrame", Vector3((-w+frame)/2, h/2, depth/2), Vector3(frame,h,depth), wood)
	_box("RightFrame", Vector3((w-frame)/2, h/2, depth/2), Vector3(frame,h,depth), wood)
	_box("TopFrame", Vector3(0,h-frame/2,depth/2), Vector3(opening.x,frame,depth), wood)
	_box("BottomFrame", Vector3(0,frame/2,depth/2), Vector3(opening.x,frame,depth), wood)
	_box("Glass", Vector3(0,h/2,depth/2), Vector3(opening.x,opening.y,0.08), _material(glass_color))
	var pane_width = (opening.x - (column_count - 1) * divider) / column_count
	var pane_height = (opening.y - (row_count - 1) * divider) / row_count
	for index in range(1, column_count):
		var x = -opening.x/2 + index * pane_width + (index-0.5) * divider
		_box("Vertical%d" % index, Vector3(x,h/2,depth/2+0.06), Vector3(divider,opening.y,depth+0.06), trim)
	for index in range(1, row_count):
		var y = frame + index * pane_height + (index-0.5) * divider
		_box("Horizontal%d" % index, Vector3(0,y,depth/2+0.06), Vector3(opening.x,divider,depth+0.06), trim)
	if show_sill and sill_depth > 0:
		_box("Sill", Vector3(0,0.06,sill_depth/2), Vector3(w+0.4,0.12,sill_depth), wood)
	return {"height": h, "opening": opening, "columns": column_count, "divider": divider}

func _material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material

func _box(name: String, at: Vector3, size: Vector3, material: Material) -> void:
	var instance = MeshInstance3D.new()
	instance.name = name
	var box = BoxMesh.new()
	box.size = size
	box.material = material
	instance.mesh = box
	instance.position = at
	add_child(instance)

