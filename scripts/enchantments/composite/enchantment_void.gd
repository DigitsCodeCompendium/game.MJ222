class_name EnchantmentVoid
extends Enchantment

@export var void_effect_scene: PackedScene
@export var void_effect_duration: float = 0.5

func after_death(cats: BattleCatsManager, self_cat: BattleCat):
	var animations: Array[Promise] = []
	
	for cat in cats.get_all_cats():
		cat.take_damage(2)
		animations.append(Promise.new(spawn_effect.bind(cats, cat.global_position)))
	
	await Promise.all(animations)

func spawn_effect(parent: Node3D, pos: Vector3):
	var effect = void_effect_scene.instantiate()
	parent.add_child(effect)
	effect.global_position = pos
	await parent.get_tree().create_timer(void_effect_duration).timeout
	effect.queue_free()
