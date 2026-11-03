class_name EnchantmentMagma
extends EnchantmentLava

func after_battle_start(cats: BattleCatsManager, self_cat: BattleCat):
	self_cat.attack = maxi(0, self_cat.attack - 3)
	cats.notify_ability_activated(self_cat)
