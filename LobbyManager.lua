-- LobbyManager.lua (Script)
-- Path: ServerScriptService/Script/LobbyManager.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")

-- Memanggil LevelManager agar event PlayerAdded-nya aktif di Lobby
-- Memanggil modul-modul yang diperlukan agar event PlayerAdded-nya aktif di Lobby
local LevelManager = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local ProfileModule = require(ServerScriptService.ModuleScript:WaitForChild("ProfileModule"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteFunction for Profile Data
local profileRemoteFunction = Instance.new("RemoteFunction")
profileRemoteFunction.Name = "GetProfileData"
profileRemoteFunction.Parent = ReplicatedStorage

profileRemoteFunction.OnServerInvoke = function(player)
    return ProfileModule.GetProfileData(player)
end
