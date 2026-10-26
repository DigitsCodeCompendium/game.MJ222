class_name EnchantmentElectric
extends Enchantment

@export var lightning_scene: PackedScene
@export var lightning_scale: Vector3 = Vector3(2, 10, 2)
@export var lightning_duration: float = 0.4

func after_ally_attack(cats: BattleCatsManager, self_cat: BattleCat):
	var opponent_team = cats.get_opposing_team(cats.get_cat_team(self_cat))
	
	if opponent_team.size() <= 0:
		return
	
	var target = opponent_team[GameManager.rng.randi_range(0, opponent_team.size() - 1)]
	target.take_damage(1)
	
	var tween = cats.create_tween()
	tween.tween_callback(_spawn_lightning.bind(cats, self_cat.global_position, lightning_duration))
	tween.tween_interval(lightning_duration / 2)
	tween.tween_callback(_spawn_lightning.bind(cats, target.global_position, lightning_duration))
	tween.tween_interval(lightning_duration / 2)
	await tween.finished

func _spawn_lightning(parent: Node3D, pos: Vector3, lifetime: float):
	var lightning = lightning_scene.instantiate() as Node3D
	parent.add_child(lightning)
	lightning.global_position = pos
	lightning.scale = lightning_scale
	await parent.get_tree().create_timer(lifetime, false).timeout
	lightning.queue_free()
