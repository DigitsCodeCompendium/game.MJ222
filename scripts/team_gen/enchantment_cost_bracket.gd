class_name EnchantmentCostBracket
extends Resource

const PRICES = preload("res://scripts/game_prices.gd")
enum Tier { BASIC, TIER_1, TIER_2, TIER_3, TIER_4 }

@export var tier: Tier = Tier.BASIC
## Price is derived from the central constants, never stored in a resource.
var cost: int:
	get:
		match tier:
			Tier.TIER_1: return PRICES.TIER_1
			Tier.TIER_2: return PRICES.TIER_2
			Tier.TIER_3: return PRICES.TIER_3
			Tier.TIER_4: return PRICES.TIER_4
			_: return PRICES.CAT

@export var weight_early: float = 1
@export var weight_late: float = 1
@export var base_attack: int
@export var base_health: int
@export var enchantments: Array[Enchantment]
