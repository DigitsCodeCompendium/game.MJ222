class_name EnchantmentGlass
extends Enchantment

func prepare_battle_start(_cats: BattleCatsManager, self_cat: BattleCat) -> void:
	self_cat.health = 1

func finalize_battle_start(_cats: BattleCatsManager, self_cat: BattleCat) -> void:
	# Opening ally buffs cannot raise starting health; opening damage can still faint it.
	self_cat.health = mini(self_cat.health, 1)

func after_death(cats: BattleCatsManager, self_cat: BattleCat) -> void:
	cats.add_glass_shards(cats.get_opposing_team(self_cat.battle_team))
	cats.notify_ability_activated(self_cat)
