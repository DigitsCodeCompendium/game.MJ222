class_name EnchantmentVolcano
extends Enchantment

@export var lava_enchantment: Enchantment

func refresh_battle_passives(cats: BattleCatsManager, self_cat: BattleCat) -> void:
	var previous: int = self_cat.ability_state.get(&"volcano_previous_health", self_cat.health)
	self_cat.ability_state[&"volcano_previous_health"] = self_cat.health
	if self_cat.ability_state.get(&"volcano_erupted", false) or self_cat.base_health <= 0:
		return
	if previous * 2 >= self_cat.base_health and self_cat.health * 2 < self_cat.base_health:
		self_cat.ability_state[&"volcano_erupted"] = true
		var team = cats.get_cat_team(self_cat)
		cats.queue_summon(team, "Lava", lava_enchantment, lava_enchantment.base_attack, lava_enchantment.base_health, self_cat, 0)
