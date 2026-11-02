extends PanelContainer

const MEMBER_CARD = preload("res://scenes/prep_area/opponent_preview_card.tscn")
var team: Array[CatData] = []

func _ready() -> void:
	GameManager.progress_changed.connect(_refresh)
	_refresh.call_deferred()

func _refresh() -> void:
	for child in $Content/Team.get_children():
		$Content/Team.remove_child(child)
		child.queue_free()
	team = GameManager.get_next_opponent_team()
	$Content/Heading.text = "CHOOSE YOUR NEXT STAGE ON THE MAP" if GameManager.route.awaiting_choice else "STAGE %d / LEVEL %d  -  NEXT OPPONENT" % [int(GameManager.route.current().depth) + 1, GameManager.route.level + 1]
	if team.is_empty() and not GameManager.route.awaiting_choice:
		$Content/Heading.text = "NO OPPONENTS AVAILABLE"
	for data in team:
		var card = MEMBER_CARD.instantiate()
		card.data = data
		$Content/Team.add_child(card)
