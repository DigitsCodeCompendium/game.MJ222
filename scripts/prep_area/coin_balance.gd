extends Label

func _ready() -> void:
	GameManager.money_changed.connect(_update_balance)
	_update_balance(GameManager.player_money)

func _update_balance(balance: int) -> void:
	text = "Coins: %d" % balance
