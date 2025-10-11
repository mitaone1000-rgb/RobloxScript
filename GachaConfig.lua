-- GachaConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GachaConfig.lua
-- This module contains all the configuration settings for the gacha system.
local GachaConfig = {
	GACHA_COST = 100,

	RARITY_CHANCES = {
		Legendary = 5,  -- Chance in percent (5%)
		Common = 95, -- Chance in percent (95%)
	},

	COMMON_REWARD_RANGE = {
		Min = 10, 
		Max = 50
	},

	PITY_THRESHOLD = 50 -- The number of rolls to guarantee a Legendary prize
}

return GachaConfig
