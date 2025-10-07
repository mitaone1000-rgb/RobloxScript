-- LobbyManager.lua (Script)
-- Path: ServerScriptService/Script/LobbyManager.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")

-- Memanggil LevelManager agar event PlayerAdded-nya aktif di Lobby
-- Memanggil modul-modul yang diperlukan agar event PlayerAdded-nya aktif di Lobby
local LevelManager = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
