extends PanelContainer

const MEMBER_CARD = preload("res://scenes/prep_area/opponent_preview_card.tscn")
var team: Array[CatData] = []

func _ready() -> void:
	_refresh.call_deferred()

func _refresh() -> void:
	team = GameManager.get_next_opponent_team()
	$Content/Heading.text = "ROUND %d  /  NEXT OPPONENT" % (GameManager.stage_index + 1)
	for data in team:
		var card = MEMBER_CARD.instantiate()
		card.data = data
		$Content/Team.add_child(card)
