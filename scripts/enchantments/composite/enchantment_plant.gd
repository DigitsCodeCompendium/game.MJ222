class_name EnchantmentPlant
extends Enchantment

@export var enchantment_cat: Enchantment

@export var absorb_orb_scene: PackedScene
@export var absorb_arc_height: float = 1
@export var absorb_duration: float = 0.4

func before_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var animations: Array[Promise] = []
	
	var front_cat = cats.get_front_adjacent_cat(self_cat)
	if front_cat != null:
		if absorb_water(self_cat, front_cat):
			animations.append(Promise.new(animate_absorb_water.bind(cats, front_cat.position, self_cat.position)))
	
	var back_cat = cats.get_back_adjacent_cat(self_cat)
	if back_cat != null:
		if absorb_water(self_cat, back_cat):
			animations.append(Promise.new(animate_absorb_water.bind(cats, back_cat.position, self_cat.position)))
	
	if animations.size() > 0:
		await Promise.all(animations)

func absorb_water(self_cat: BattleCat, target_cat: BattleCat) -> bool:
	if target_cat.enchantment is EnchantmentWater:
		target_cat.set_enchantment(enchantment_cat)
		self_cat.health += 1
		self_cat.attack += 1
		return true
	elif target_cat.enchantment.component1 is EnchantmentWater:
		target_cat.set_enchantment(target_cat.enchantment.component2)
		self_cat.health += 1
		self_cat.attack += 1
		return true
	elif target_cat.enchantment.component2 is EnchantmentWater:
		target_cat.set_enchantment(target_cat.enchantment.component1)
		self_cat.health += 1
		self_cat.attack += 1
		return true
	return false

func animate_absorb_water(parent: Node3D, from_pos: Vector3, to_pos: Vector3):
	var water_orb = absorb_orb_scene.instantiate()
	parent.add_child(water_orb)
	var tween = parent.create_tween()
	tween.tween_method(_tween_orb_pos.bind(water_orb, from_pos, to_pos), 0.0, 1.0, absorb_duration).set_ease(Tween.EASE_OUT)
	await tween.finished
	water_orb.queue_free()

func _tween_orb_pos(t: float, orb: Node3D, from_pos: Vector3, to_pos: Vector3):
	var base_pos = from_pos.lerp(to_pos, t)
	var y_factor = sqrt(pingpong(t * 2, 1))
	orb.position = base_pos + Vector3(0, absorb_arc_height * y_factor, 0)
