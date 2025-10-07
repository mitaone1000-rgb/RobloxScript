-- CoinsModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/CoinsModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul DataStoreManager
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))
local StatsModule = require(ServerScriptService.ModuleScript:WaitForChild("StatsModule"))

-- RemoteEvent untuk pembaruan di sisi client
local CoinsUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("CoinsUpdateEvent")
if not CoinsUpdateEvent then
	CoinsUpdateEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	CoinsUpdateEvent.Name = "CoinsUpdateEvent"
end

local CoinsManager = {}
local NEW_SCOPE = "Inventory"
local OLD_SCOPE = "Coins"
local DEFAULT_DATA = {Coins = 0}

-- Fungsi untuk mendapatkan data koin pemain (mengembalikan tabel)
function CoinsManager.GetData(player)
	local data = DataStoreManager.GetData(player, NEW_SCOPE)

	-- Penanganan data korup: jika data adalah angka, perbaiki.
	if type(data) == "number" then
		local fixedData = {Coins = data}
		DataStoreManager.SaveData(player, NEW_SCOPE, fixedData)
		return fixedData
	end

	if data == nil then
		-- Coba migrasi dari scope lama (yang datanya berupa angka)
		local oldData = DataStoreManager.GetData(player, OLD_SCOPE)
		if oldData ~= nil then
			-- Data lama ditemukan, bungkus dalam format baru
			local newData = {Coins = oldData}
			DataStoreManager.SaveData(player, NEW_SCOPE, newData)
			DataStoreManager.RemoveDataByUserId(player.UserId, OLD_SCOPE) -- Hapus data lama
			return newData
		end
	end
	
	return data or DEFAULT_DATA
end

-- Fungsi untuk menambahkan koin
function CoinsManager.AddCoins(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end

	-- Karena data adalah tabel, kita tidak bisa pakai IncrementData
	local data = CoinsManager.GetData(player)
	data.Coins = data.Coins + amount
	DataStoreManager.SaveData(player, NEW_SCOPE, data)

	-- Kirim pembaruan ke client
	CoinsUpdateEvent:FireClient(player, data.Coins)

	-- Lacak total koin seumur hidup
	if StatsModule and StatsModule.AddCoin then
		StatsModule.AddCoin(player, amount)
	end

	return data.Coins
end

-- Fungsi untuk mendapatkan data koin berdasarkan UserID (untuk admin, mengembalikan tabel)
function CoinsManager.GetDataByUserId(userId)
	local data = DataStoreManager.GetDataByUserId(userId, NEW_SCOPE)

	-- Penanganan data korup: jika data adalah angka, perbaiki.
	if type(data) == "number" then
		local fixedData = {Coins = data}
		DataStoreManager.SaveDataByUserId(userId, NEW_SCOPE, fixedData)
		return fixedData
	end

	if data == nil then
		-- Coba migrasi dari scope lama
		local oldData = DataStoreManager.GetDataByUserId(userId, OLD_SCOPE)
		if oldData ~= nil then
			local newData = {Coins = oldData}
			DataStoreManager.SaveDataByUserId(userId, NEW_SCOPE, newData)
			DataStoreManager.RemoveDataByUserId(userId, OLD_SCOPE)
			return newData
		end
	end

	return data or DEFAULT_DATA
end

-- Fungsi untuk mengubah jumlah koin berdasarkan UserID (untuk admin)
function CoinsManager.SetDataByUserId(userId, amount)
	if not userId or type(amount) ~= "number" then
		return false, "Invalid arguments"
	end

	-- Simpan data dalam format tabel
	local newData = {Coins = amount}
	local success, message = DataStoreManager.SaveDataByUserId(userId, NEW_SCOPE, newData)
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
	local initialData = CoinsManager.GetData(player)
	CoinsUpdateEvent:FireClient(player, initialData.Coins)
end

-- Event listener saat pemain bergabung
Players.PlayerAdded:Connect(onPlayerAdded)

-- Tidak perlu PlayerRemoving, karena DataStoreManager sudah menanganinya.

return CoinsManager
