extends PanelContainer

func _ready() -> void:
	GameManager.progress_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	$Content/Lives.text = "Lives left: %d" % maxi(GameManager.player_life, 0)
	var route = GameManager.route
	$Content/Rounds.text = "Stage %d/%d  |  Level %d/%d" % [int(route.current().get("depth", 0)) + 1, route.layers.size(), mini(route.level + 1, route.LEVELS_PER_STAGE), route.LEVELS_PER_STAGE]
	if route.awaiting_choice:
		$Content/Stakes.text = "Stage complete! Choose a route on the map."
	elif route.is_final_level():
		$Content/Stakes.text = "You must win"
	else:
		var stakes = GameManager.get_loss_stakes()
		$Content/Stakes.text = "No lives lost on defeat" if stakes == 0 else "Lose %d %s on defeat" % [stakes, "life" if stakes == 1 else "lives"]
