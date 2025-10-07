-- DataStoreManager.lua (ModuleScript)
-- Path: ServerScriptService/Modules/DataStoreManager.lua
-- Script Place: Lobby & ACT 1: Village

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DATASTORE_NAME = "Player_dev"

local DataStoreManager = {}
local dataStores = {}
local playerDataCache = {}
local saveDebounce = {}

-- Fungsi untuk mendapatkan atau membuat DataStore
local function getStore(scope)
	if not dataStores[scope] then
		dataStores[scope] = DataStoreService:GetDataStore(DATASTORE_NAME, scope)
	end
	return dataStores[scope]
end

-- Fungsi untuk memuat data pemain
function DataStoreManager.GetData(player, scope)
	local playerCache = playerDataCache[player]
	if playerCache and playerCache[scope] then
		return playerCache[scope]
	end

	local store = getStore(scope)
	local success, data = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)

	if success then
		if not playerDataCache[player] then
			playerDataCache[player] = {}
		end
		playerDataCache[player][scope] = data
		return data
	else
		warn("DataStoreManager: Gagal memuat data untuk " .. player.Name .. " di scope " .. scope .. ". Error: " .. tostring(data))
		return nil
	end
end

-- Fungsi untuk menyimpan data pemain
function DataStoreManager.SaveData(player, scope, data)
	if not player or not scope or data == nil then return end

	-- Update cache
	if not playerDataCache[player] then
		playerDataCache[player] = {}
	end
	playerDataCache[player][scope] = data

	-- Cek debounce
	local debounceKey = player.UserId .. "_" .. scope
	if saveDebounce[debounceKey] then return end
	saveDebounce[debounceKey] = true

	local store = getStore(scope)
	local success, err = pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn("DataStoreManager: Gagal menyimpan data untuk " .. player.Name .. " di scope " .. scope .. ". Error: " .. tostring(err))
	end

	-- Hapus debounce setelah 5 detik
	task.delay(5, function()
		saveDebounce[debounceKey] = nil
	end)
end

-- Fungsi untuk menginkrementasi nilai data
function DataStoreManager.IncrementData(player, scope, amount)
	if not player or not scope or type(amount) ~= "number" or amount == 0 then return end

	local currentData = DataStoreManager.GetData(player, scope) or 0
	if type(currentData) ~= "number" then
		warn("DataStoreManager: Tidak dapat menginkrementasi data non-numerik untuk " .. player.Name .. " di scope " .. scope)
		return
	end

	local newData = currentData + amount
	DataStoreManager.SaveData(player, scope, newData)
	return newData
end


-- Fungsi untuk menangani saat pemain keluar
-- Fungsi untuk mendapatkan data berdasarkan UserID
function DataStoreManager.GetDataByUserId(userId, scope)
	local store = getStore(scope)
	local success, data = pcall(function()
		return store:GetAsync("Player_" .. userId)
	end)

	if success then
		return data
	else
		warn("DataStoreManager: Gagal memuat data untuk UserID " .. userId .. " di scope " .. scope .. ". Error: " .. tostring(data))
		return nil
	end
end

-- Fungsi untuk menyimpan data berdasarkan UserID
function DataStoreManager.SaveDataByUserId(userId, scope, data)
	if not userId or not scope or data == nil then return false, "Invalid arguments" end

	local store = getStore(scope)
	local success, err = pcall(function()
		store:SetAsync("Player_" .. userId, data)
	end)

	if not success then
		warn("DataStoreManager: Gagal menyimpan data untuk UserID " .. userId .. " di scope " .. scope .. ". Error: " .. tostring(err))
		return false, tostring(err)
	end
	return true, "Data updated successfully"
end

-- Fungsi untuk menghapus data berdasarkan UserID
function DataStoreManager.RemoveDataByUserId(userId, scope)
	if not userId or not scope then return false, "Invalid arguments" end

	local store = getStore(scope)
	local success, err = pcall(function()
		store:RemoveAsync("Player_" .. userId)
	end)

	if not success then
		warn("DataStoreManager: Gagal menghapus data untuk UserID " .. userId .. " di scope " .. scope .. ". Error: " .. tostring(err))
		return false, tostring(err)
	end
	return true, "Data removed successfully"
end

-- Fungsi untuk menangani saat pemain keluar
local function onPlayerRemoving(player)
	local playerCache = playerDataCache[player]
	if playerCache then
		for scope, data in pairs(playerCache) do
			DataStoreManager.SaveData(player, scope, data)
		end
		playerDataCache[player] = nil -- Hapus dari cache
	end
end

-- Ikat fungsi ke event PlayerRemoving
Players.PlayerRemoving:Connect(onPlayerRemoving)

return DataStoreManager
