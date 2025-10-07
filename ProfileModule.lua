-- ProfileModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/ProfileModule.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")
local LevelModule = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))
local StatsModule = require(ServerScriptService.ModuleScript:WaitForChild("StatsModule"))

local ProfileModule = {}

function ProfileModule.GetProfileData(player)
    if not player then return nil end

    -- Get data from modules
    local levelData = LevelModule.GetData(player)
    local statsData = StatsModule.GetData(player)

    -- Prepare the data to be sent to the client
    local profileData = {
        Name = player.Name,
        Level = levelData.Level,
        XP = levelData.XP,
        TotalCoins = statsData.TotalCoins,
        TotalKills = statsData.TotalKills,
        TotalRevives = statsData.TotalRevives,
        TotalKnocks = statsData.TotalKnocks,
        TotalPlaytime = statsData.TotalPlaytime
    }

    return profileData
end

return ProfileModule