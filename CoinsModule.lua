-- CoinsModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/CoinsModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul DataStoreManager
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

-- RemoteEvent untuk pembaruan di sisi client
local CoinsUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("CoinsUpdateEvent")
if not CoinsUpdateEvent then
	CoinsUpdateEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	CoinsUpdateEvent.Name = "CoinsUpdateEvent"
end

local CoinsManager = {}
local NEW_SCOPE = "Inventory"
local OLD_SCOPE = "Coins"

-- Fungsi untuk mendapatkan data koin pemain
function CoinsManager.GetData(player)
	local data = DataStoreManager.GetData(player, NEW_SCOPE)

	if data == nil then
		-- Coba migrasi dari scope lama
		local oldData = DataStoreManager.GetData(player, OLD_SCOPE)
		if oldData ~= nil then
			-- Data ditemukan di scope lama, migrasikan
			DataStoreManager.SaveData(player, NEW_SCOPE, oldData)
			DataStoreManager.RemoveDataByUserId(player.UserId, OLD_SCOPE) -- Hapus data lama
			return oldData
		end
	end

	return data or 0
end

-- Fungsi untuk menambahkan koin
function CoinsManager.AddCoins(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end

	-- Menggunakan IncrementData dari DataStoreManager untuk atomisitas
	local newTotal = DataStoreManager.IncrementData(player, NEW_SCOPE, amount)

	-- Kirim pembaruan ke client
	if newTotal then
		CoinsUpdateEvent:FireClient(player, newTotal)
	end

	return newTotal
end

-- Fungsi untuk mendapatkan data koin berdasarkan UserID (untuk admin)
function CoinsManager.GetDataByUserId(userId)
	local data = DataStoreManager.GetDataByUserId(userId, NEW_SCOPE)

	if data == nil then
		-- Coba migrasi dari scope lama
		local oldData = DataStoreManager.GetDataByUserId(userId, OLD_SCOPE)
		if oldData ~= nil then
			-- Data ditemukan di scope lama, migrasikan
			DataStoreManager.SaveDataByUserId(userId, NEW_SCOPE, oldData)
			DataStoreManager.RemoveDataByUserId(userId, OLD_SCOPE) -- Hapus data lama
			return oldData
		end
	end

	return data or 0
end

-- Fungsi untuk mengubah data koin berdasarkan UserID (untuk admin)
function CoinsManager.SetDataByUserId(userId, amount)
	if not userId or type(amount) ~= "number" then
		return false, "Invalid arguments"
	end

	local success, message = DataStoreManager.SaveDataByUserId(userId, NEW_SCOPE, amount)
	if success then
		local player = Players:GetPlayerByUserId(userId)
		if player then
			CoinsUpdateEvent:FireClient(player, amount)
		end
	end
	return success, message
end

-- Fungsi untuk menghapus data koin berdasarkan UserID (untuk admin)
function CoinsManager.RemoveDataByUserId(userId)
	-- Hapus dari kedua scope untuk memastikan kebersihan data
	DataStoreManager.RemoveDataByUserId(userId, OLD_SCOPE)
	local success, message = DataStoreManager.RemoveDataByUserId(userId, NEW_SCOPE)

	if success then
		local player = Players:GetPlayerByUserId(userId)
		if player then
			CoinsUpdateEvent:FireClient(player, 0) -- Reset ke 0 di client
		end
	end
	return success, message
end

-- Setup saat pemain bergabung
local function onPlayerAdded(player)
	-- Muat data koin awal untuk mengisi cache dan kirim ke client
	local initialCoins = CoinsManager.GetData(player)
	CoinsUpdateEvent:FireClient(player, initialCoins)
end

-- Event listener saat pemain bergabung
Players.PlayerAdded:Connect(onPlayerAdded)

-- Tidak perlu PlayerRemoving, karena DataStoreManager sudah menanganinya.

return CoinsManager
