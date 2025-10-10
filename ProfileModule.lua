-- ProfileModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/ProfileModule.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")
local LevelModule = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))
local StatsModule = require(ServerScriptService.ModuleScript:WaitForChild("StatsModule"))
local CoinsModule = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule")) -- Tambahkan modul koin

local ProfileModule = {}

function ProfileModule.GetProfileData(player)
    if not player then return nil end

    -- Get data from modules
    local levelData = LevelModule.GetData(player)
    local statsData = StatsModule.GetData(player)
    local coinsData = CoinsModule.GetData(player) -- Ambil data koin saat ini

    -- Prepare the data to be sent to the client
    local profileData = {
        Name = player.Name,
        Level = levelData.Level,
        XP = levelData.XP,
        CurrentCoins = coinsData.Coins, -- Tambahkan koin saat ini
        TotalCoins = statsData.TotalCoins,
        TotalKills = statsData.TotalKills,
        TotalRevives = statsData.TotalRevives,
        TotalKnocks = statsData.TotalKnocks
    }

    return profileData
end

return ProfileModule