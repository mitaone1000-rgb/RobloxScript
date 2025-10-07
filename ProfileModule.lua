-- ProfileModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/ProfileModule.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")
local LevelModule = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))

local ProfileModule = {}

function ProfileModule.GetProfileData(player)
	if not player then return nil end

	-- Get data from LevelModule
	local levelData = LevelModule.GetData(player)

	-- Prepare the data to be sent to the client
	local profileData = {
		Name = player.Name,
		Level = levelData.Level,
		XP = levelData.XP
	}

	return profileData
end

return ProfileModule
