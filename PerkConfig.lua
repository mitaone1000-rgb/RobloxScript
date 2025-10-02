-- PerkConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/PerkConfig.lua

local PerkConfig = {}

PerkConfig.Perks = {
	HPPlus = {
		Cost = 3000,
		Description = "Increases maximum health 30%",
		Icon = "❤️"
	},
	StaminaPlus = {
		Cost = 3000,
		Description = "Increases maximum stamina 30%",
		Icon = "⚡"
	},
	ReloadPlus = {
		Cost = 3000,
		Description = "Reload time 30% faster",
		Icon = "🔧"
	},
	RevivePlus = {
		Cost = 3000,
		Description = "Revive time 50% faster",
		Icon = "🔄"
	},
	RateBoost = {
		Cost = 3000,
		Description = "Fire rate 30% faster",
		Icon = "🚀"
	}
}

return PerkConfig