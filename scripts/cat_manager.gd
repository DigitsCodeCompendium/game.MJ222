extends Node3D
class_name CatManager

const CAT_SCENE = preload("res://scenes/cat/cat_test.tscn")

@export var possible_enchantments: Array[Enchantment]
@export var possible_names: Array[String] = ["Qwill", "Max", "Fish", "Spot"]
## Maximum number of active prep cats. Cats queued for deletion free their slot immediately.
@export_range(0, 100, 1) var cat_limit: int = 10
@export var cat_beds: Array[CatBed]

var used_names: Array[String]:
	get:
		var names: Array[String] = []
		for cat in get_cats():
			names.append(cat.cat_name)
		return names

func get_cats() -> Array[Cat]:
	var cats: Array[Cat] = []
	for child in get_children():
		if child is Cat and not child.is_queued_for_deletion():
			cats.append(child)
	return cats

func get_cat_count() -> int:
	return get_cats().size()

func can_spawn_cat(amount: int = 1) -> bool:
	return get_cat_count() + amount <= cat_limit

func get_unique_name(preferred: String = "") -> String:
	var taken: Array[String] = []
	for existing in used_names:
		taken.append(existing.strip_edges().to_lower())
	preferred = preferred.strip_edges()
	if not preferred.is_empty() and not taken.has(preferred.to_lower()):
		return preferred
	var available: Array[String] = []
	for candidate in possible_names:
		candidate = candidate.strip_edges()
		if not candidate.is_empty() and not taken.has(candidate.to_lower()) and not available.has(candidate):
			available.append(candidate)
	if not available.is_empty():
		return available.pick_random()
	# A short name list should not prevent filling otherwise available cat slots.
	var base = preferred if not preferred.is_empty() else "Cat"
	if preferred.is_empty():
		for candidate in possible_names:
			if not candidate.strip_edges().is_empty():
				base = candidate.strip_edges()
				break
	var suffix = 2
	var result = base
	while taken.has(result.to_lower()):
		result = "%s %d" % [base, suffix]
		suffix += 1
	return result

func add_cat(cat: Cat) -> bool:
	if not can_spawn_cat() or cat.get_parent() != null:
		return false
	cat.cat_name = get_unique_name(cat.cat_name)
	add_child(cat)
	return true

func remove_cat(cat: Cat) -> void:
	if is_instance_valid(cat) and cat.get_parent() == self:
		cat.queue_free()

func get_held_cat() -> Cat:
	for child in get_children():
		if child is Cat and child.is_picked and not child.is_queued_for_deletion():
			return child
	return null

## Returns null without creating a cat when the limit is reached.
func spawn_cat(pos: Vector3, cat_data: CatData = null) -> Cat:
	if not can_spawn_cat():
		return null
	var selected_enchantment: Enchantment
	if cat_data != null:
		selected_enchantment = cat_data.enchantment
	else:
		var valid = possible_enchantments.filter(func(e): return e != null)
		if valid.is_empty():
			return null
		selected_enchantment = valid.pick_random()
	var cat_instance = CAT_SCENE.instantiate() as Cat
	cat_instance.cat_name = get_unique_name(cat_data.cat_name if cat_data != null else "")
	cat_instance.attack_offset = cat_data.attack_offset if cat_data != null else 0
	cat_instance.health_offset = cat_data.health_offset if cat_data != null else 0
	cat_instance.set_enchantment(selected_enchantment)
	# Set the local position before _ready so the cat starts at the requested world point.
	cat_instance.position = to_local(pos)
	if not add_cat(cat_instance):
		cat_instance.free()
		return null
	return cat_instance
