class_name EnchantmentSteam
extends Enchantment

func handle_attack_damage(cats: BattleCatsManager, self_cat: BattleCat, amount: int):
	@warning_ignore("integer_division") # Transfer amount should round down
	var transfer_amount = amount / 2
	self_cat.take_damage(amount - transfer_amount)
	
	var back_cat = cats.get_back_adjacent_cat(self_cat)
	if back_cat != null:
		back_cat.take_damage(transfer_amount)
	
	var cat_model = self_cat.visual._model
	if cat_model != null:
		var steam_jet = cat_model.get_node("Effects/SteamJet")
		if steam_jet is CPUParticles3D:
			var tween = cats.create_tween()
			tween.tween_property(steam_jet, "emitting", true, 0).set_delay(cats.direct_attack_hurt_delay)
	
