class_name EnchantmentMagma
extends EnchantmentLava

func after_battle_start(_cats: BattleCatsManager, self_cat: BattleCat):
	self_cat.attack = maxi(0, self_cat.attack - 3)
