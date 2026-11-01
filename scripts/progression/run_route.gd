extends RefCounted

const LEVELS_PER_STAGE = 6
var nodes: Dictionary = {}
var layers: Array[PackedStringArray] = []
var current_id: String = ""
var visited: PackedStringArray = []
var completed: PackedStringArray = []
var level: int = 0
var awaiting_choice: bool = false
var finished: bool = false

func generate(random: RandomNumberGenerator, widths: Array[int]) -> void:
	nodes.clear()
	layers.clear()
	visited.clear()
	completed.clear()
	level = 0
	awaiting_choice = false
	finished = false
	var names = ["Mosswood", "Sunlit Grove", "Stone Hollow", "Cloudbank", "Ember Ridge", "Moonlit Marsh", "Crystal Vale", "Fern Hollow", "Amber Fields", "Old Ruins", "Starlit Pond", "Windy Bluff", "Bloomwood", "Frost Hollow", "Silver Glade"]
	for depth in range(widths.size()):
		var layer = PackedStringArray()
		var width = random.randi_range(2, 3) if widths[depth] == 0 else maxi(1, widths[depth])
		for lane in range(width):
			var id = "%d_%d" % [depth, lane]
			var title = "Home Trail" if depth == 0 else ("Last Stand" if depth == widths.size() - 1 else str(names[((depth - 1) * 3 + lane) % names.size()]))
			nodes[id] = {"id": id, "depth": depth, "lane": lane, "title": title, "seed": random.randi(), "next": PackedStringArray()}
			layer.append(id)
		layers.append(layer)
	# Every node has a way forward and every destination has an incoming path.
	for depth in range(layers.size() - 1):
		var from = layers[depth]
		var to = layers[depth + 1]
		for source in from:
			var nearest = _nearest_ids(source, to)
			_link(source, nearest[random.randi_range(0, nearest.size() - 1)])
		for destination in to:
			var incoming = false
			for source in from:
				incoming = incoming or destination in nodes[source].next
			if not incoming:
				var nearest = _nearest_ids(destination, from)
				_link(nearest[random.randi_range(0, nearest.size() - 1)], destination)
		# Optional branches stay nearby and cannot cross an existing connection.
		for source in from:
			if to.size() <= 1 or random.randf() >= 0.4:
				continue
			var candidates = PackedStringArray()
			for destination in to:
				if destination in nodes[source].next:
					continue
				if absf(_node_y(source) - _node_y(destination)) > 0.5001:
					continue
				if not _crosses_existing(source, destination, from):
					candidates.append(destination)
			if not candidates.is_empty():
				var nearest = _nearest_ids(source, candidates)
				_link(source, nearest[random.randi_range(0, nearest.size() - 1)])
	current_id = layers[0][0]
	visited.append(current_id)

## Shared by route generation and drawing so proximity matches the visible map.
func lane_position(lane: int, count: int) -> float:
	if count == 2:
		return 0.35 if lane == 0 else 0.65
	return (float(lane) + 0.5) / maxf(1.0, count)

func _node_y(id: String) -> float:
	return lane_position(nodes[id].lane, layers[nodes[id].depth].size())

func _nearest_ids(id: String, candidates: PackedStringArray) -> PackedStringArray:
	var nearest = PackedStringArray()
	var best = INF
	for candidate in candidates:
		var distance = absf(_node_y(id) - _node_y(candidate))
		if distance < best and not is_equal_approx(distance, best):
			best = distance
			nearest.clear()
		if is_equal_approx(distance, best):
			nearest.append(candidate)
	return nearest

func _crosses_existing(source: String, destination: String, from: PackedStringArray) -> bool:
	for other_source in from:
		for other_destination in nodes[other_source].next:
			if (int(nodes[source].lane) - int(nodes[other_source].lane)) * (int(nodes[destination].lane) - int(nodes[other_destination].lane)) < 0:
				return true
	return false

func _link(source: String, destination: String) -> void:
	var links: PackedStringArray = nodes[source].next
	if not destination in links:
		links.append(destination)
	nodes[source].next = links

func current() -> Dictionary:
	return nodes.get(current_id, {})

func can_choose(id: String) -> bool:
	return awaiting_choice and id in current().get("next", PackedStringArray())

func choose(id: String) -> bool:
	if not can_choose(id):
		return false
	current_id = id
	visited.append(id)
	level = 0
	awaiting_choice = false
	return true

func complete_level() -> void:
	if awaiting_choice or finished:
		return
	level += 1
	if level < LEVELS_PER_STAGE:
		return
	completed.append(current_id)
	if current().next.is_empty():
		finished = true
	else:
		awaiting_choice = true

func is_final_level() -> bool:
	return not awaiting_choice and current().get("next", []).is_empty() and level == LEVELS_PER_STAGE - 1

func battle_seed() -> int:
	return (int(current().get("seed", 0)) + level * 104729) & 0x7fffffff
