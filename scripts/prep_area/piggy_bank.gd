extends Node3D

var _flash_tween: Tween
@onready var _normal_color: Color = $CoinCount.modulate

func _ready() -> void:
	GameManager.money_changed.connect(_update_balance)
	GameManager.insufficient_funds.connect(_flash_insufficient_funds)
	_update_balance(GameManager.player_money)

func _update_balance(balance: int) -> void:
	$CoinCount.text = "%d coins" % balance

func _flash_insufficient_funds(_cost: int) -> void:
	if _flash_tween != null and _flash_tween.is_running():
		return
	_flash_tween = create_tween()
	for i in range(3):
		_flash_tween.tween_property($CoinCount, "modulate", Color("ff4545"), 0.1)
		_flash_tween.tween_interval(0.1)
		_flash_tween.tween_property($CoinCount, "modulate", _normal_color, 0.15)
		_flash_tween.tween_interval(0.1)
