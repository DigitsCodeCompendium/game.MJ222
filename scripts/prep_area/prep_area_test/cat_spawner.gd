extends Node

@export var cat_manager: CatManager

func spawn_cat():
	cat_manager.spawn_cat(cat_manager.find_random_cat_spawn_pos())

func _on_spawn_cat_button_pressed() -> void:
	spawn_cat()
