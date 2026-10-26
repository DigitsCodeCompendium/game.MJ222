extends PanelContainer

@onready var card: PanelContainer = $CenterContainer/Card
var _entrance: Tween

func present(title: String, accent: Color, round_number: int, lives: int, run_finished: bool, lives_lost: int = 0) -> void:
	var style = card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = accent
	card.add_theme_stylebox_override("panel", style)
	%ResultLabel.text = title
	%ResultLabel.add_theme_color_override("font_color", accent)
	%RoundLabel.visible = not run_finished
	%RoundLabel.text = "ROUND %d COMPLETE" % round_number
	%RoundLabel.add_theme_color_override("font_color", accent.lightened(0.2))
	%PlayerLifeLabel.text = "%d %s remaining" % [maxi(lives, 0), "life" if lives == 1 else "lives"]
	%LifeLossLabel.visible = lives_lost > 0
	%LifeLossLabel.text = "Lost %d %s!" % [lives_lost, "life" if lives_lost == 1 else "lives"]
	if lives_lost > 0:
		%PlayerLifeLabel.text = "Lives: %d to %d" % [lives + lives_lost, maxi(lives, 0)]
	%ContinueButton.text = "Back to main menu"
	show()
	if _entrance != null:
		_entrance.kill()
	modulate.a = 0.0
	_entrance = create_tween()
	_entrance.tween_property(self, "modulate:a", 1.0, 0.25)
