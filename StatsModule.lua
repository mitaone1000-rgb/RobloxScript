-- StatsModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/StatsModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul DataStoreManager
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

local StatsModule = {}
local SCOPE = "Stats"
local OLD_SCOPE = "LifetimeStats"
local DEFAULT_DATA = {
	TotalCoins = 0,
	TotalKills = 0,
	TotalRevives = 0,
	TotalKnocks = 0
}

-- Fungsi untuk mendapatkan data statistik pemain
function StatsModule.GetData(player)
	local data = DataStoreManager.GetData(player, SCOPE)

	-- Jika tidak ada data di scope baru, coba migrasi dari scope lama
	if data == nil then
		local oldData = DataStoreManager.GetData(player, OLD_SCOPE)
		if oldData then
			warn("Migrating data for player " .. player.Name .. " from " .. OLD_SCOPE .. " to " .. SCOPE)
			DataStoreManager.SaveData(player, SCOPE, oldData)
			DataStoreManager.RemoveDataByUserId(player.UserId, OLD_SCOPE) -- Hapus data lama
			data = oldData
		end
	end

	if data == nil then
		return table.clone(DEFAULT_DATA) -- Return a copy to prevent mutation
	end

	-- Fill in any missing default values
	local hasChanges = false
	for key, value in pairs(DEFAULT_DATA) do
		if data[key] == nil then
			data[key] = value
			hasChanges = true
		end
	end

	if hasChanges then
		DataStoreManager.SaveData(player, SCOPE, data)
	end

	return data
end

-- Fungsi internal untuk menambah nilai tertentu
local function incrementStat(player, key, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end

	local data = StatsModule.GetData(player)
	data[key] = (data[key] or 0) + amount
	DataStoreManager.SaveData(player, SCOPE, data)
end

-- Fungsi publik untuk menambah statistik
function StatsModule.AddKill(player)
	incrementStat(player, "TotalKills", 1)
end

function StatsModule.AddCoin(player, amount)
	incrementStat(player, "TotalCoins", amount)
end

function StatsModule.AddKnock(player)
	incrementStat(player, "TotalKnocks", 1)
end

function StatsModule.AddRevive(player)
	incrementStat(player, "TotalRevives", 1)
end

-- Fungsi untuk mendapatkan data statistik berdasarkan UserID
function StatsModule.GetDataByUserId(userId)
	local data = DataStoreManager.GetDataByUserId(userId, SCOPE)

	-- Jika tidak ada data di scope baru, coba migrasi dari scope lama
	if data == nil then
		local oldData = DataStoreManager.GetDataByUserId(userId, OLD_SCOPE)
		if oldData then
			warn("Migrating data for userId " .. tostring(userId) .. " from " .. OLD_SCOPE .. " to " .. SCOPE)
			DataStoreManager.SaveDataByUserId(userId, SCOPE, oldData)
			DataStoreManager.RemoveDataByUserId(userId, OLD_SCOPE) -- Hapus data lama
			data = oldData
		end
	end

	if data == nil then
		return table.clone(DEFAULT_DATA) -- Return a copy to prevent mutation
	end

	-- Isi nilai default yang mungkin hilang
	local hasChanges = false
	for key, value in pairs(DEFAULT_DATA) do
		if data[key] == nil then
			data[key] = value
			hasChanges = true
		end
	end

	if hasChanges then
		DataStoreManager.SaveDataByUserId(userId, SCOPE, data)
	end

	return data
end

-- Setup saat pemain bergabung untuk memastikan data di-cache
local function onPlayerAdded(player)
	-- Memuat data awal untuk mengisi cache
	StatsModule.GetData(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

return StatsModule
