extends Node3D

func _ready() -> void:
	GameManager.money_changed.connect(_update_balance)
	_update_balance(GameManager.player_money)

func _update_balance(balance: int) -> void:
	$CoinCount.text = "%d coins" % balance
