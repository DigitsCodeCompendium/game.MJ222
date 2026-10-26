extends PanelContainer

func _ready() -> void:
	$Content/Lives.text = "Lives left: %d" % maxi(GameManager.player_life, 0)
	# Include the upcoming battle in the number of rounds remaining.
	$Content/Rounds.text = "Rounds left: %d" % maxi(GameManager.total_rounds - GameManager.stage_index, 0)
	var round_index = GameManager.stage_index
	if round_index == GameManager.total_rounds - 1:
		$Content/Stakes.text = "You must win"
	elif round_index >= 0 and round_index < GameManager.total_rounds:
		var stakes = GameManager.player_life_stakes[round_index]
		$Content/Stakes.text = "Lose %d %s on defeat" % [stakes, "life" if stakes == 1 else "lives"]
	else:
		$Content/Stakes.hide()
