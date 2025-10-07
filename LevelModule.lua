-- LevelModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/LevelModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul DataStoreManager
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

local LevelManager = {}
local LEVEL_SCOPE = "Level"

-- Konfigurasi: XP yang dibutuhkan per level
local XP_PER_LEVEL = 1000
local DEFAULT_DATA = { Level = 1, XP = 0 }

-- Fungsi untuk mendapatkan data pemain
function LevelManager.GetData(player)
	-- Meminta data dari DataStoreManager, gunakan data default jika tidak ada
	return DataStoreManager.GetData(player, LEVEL_SCOPE) or DEFAULT_DATA
end

-- Fungsi untuk mendapatkan data pemain berdasarkan UserID (untuk admin)
function LevelManager.GetDataByUserId(userId)
	return DataStoreManager.GetDataByUserId(userId, LEVEL_SCOPE) or DEFAULT_DATA
end

-- Fungsi untuk mengubah data pemain berdasarkan UserID (untuk admin)
function LevelManager.SetData(userId, newData)
	if not userId or not newData or type(newData.Level) ~= "number" or type(newData.XP) ~= "number" then
		return false, "Invalid arguments or data format"
	end
	return DataStoreManager.SaveDataByUserId(userId, LEVEL_SCOPE, newData)
end

-- Fungsi untuk menghapus data pemain berdasarkan UserID (untuk admin)
function LevelManager.DeleteData(userId)
	return DataStoreManager.RemoveDataByUserId(userId, LEVEL_SCOPE)
end

-- Fungsi untuk menambahkan XP
function LevelManager.AddXP(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end

	local data = LevelManager.GetData(player)
	data.XP = data.XP + amount

	-- Cek kenaikan level
	while data.XP >= XP_PER_LEVEL do
		data.XP = data.XP - XP_PER_LEVEL
		data.Level = data.Level + 1
		-- Di sini Anda bisa menambahkan event untuk notifikasi level up
	end

	-- Simpan data melalui DataStoreManager
	DataStoreManager.SaveData(player, LEVEL_SCOPE, data)

	-- Kirim update ke client
	local LevelUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("LevelUpdateEvent")
	if LevelUpdateEvent then
		LevelUpdateEvent:FireClient(player, data.Level, data.XP, XP_PER_LEVEL)
	end
end

-- Setup saat pemain bergabung
local function onPlayerAdded(player)
	local data = LevelManager.GetData(player)

	-- Kirim data awal ke client
	local LevelUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("LevelUpdateEvent")
	if LevelUpdateEvent then
		LevelUpdateEvent:FireClient(player, data.Level, data.XP, XP_PER_LEVEL)
	end
end

-- Event listener saat pemain bergabung
Players.PlayerAdded:Connect(onPlayerAdded)

-- Tidak perlu PlayerRemoving, karena DataStoreManager sudah menanganinya.

return LevelManager
