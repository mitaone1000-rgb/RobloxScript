-- PlayerData.lua (Script)
-- Path: ServerScriptService/Script/PlayerData.lua
-- Script Place: Lobby & ACT 1: Village

-- Memuat modul DataStoreManager agar sistemnya aktif
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

-- Tidak ada logika lain yang diperlukan di sini, karena DataStoreManager
-- sudah menangani semua event pemain secara internal.
