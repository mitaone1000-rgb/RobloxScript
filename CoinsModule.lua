-- CoinsModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/CoinsModule.lua
-- Script Place: Lobby & ACT 1: Village
-- Deskripsi: Mengelola logika koin pemain, terintegrasi dengan DataStoreManager.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul DataStoreManager
local DataStoreManager = require(ServerScriptService.DataStoreManager)

-- RemoteEvent untuk pembaruan di sisi client
local CoinsUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("CoinsUpdateEvent")
if not CoinsUpdateEvent then
	CoinsUpdateEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	CoinsUpdateEvent.Name = "CoinsUpdateEvent"
end

local CoinsManager = {}
local COINS_SCOPE = "Coins"

-- Fungsi untuk mendapatkan data koin pemain
function CoinsManager.GetData(player)
	-- Meminta data dari DataStoreManager, default ke 0 jika tidak ada
	return DataStoreManager.GetData(player, COINS_SCOPE) or 0
end

-- Fungsi untuk menambahkan koin
function CoinsManager.AddCoins(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end

	-- Menggunakan IncrementData dari DataStoreManager untuk atomisitas
	local newTotal = DataStoreManager.IncrementData(player, COINS_SCOPE, amount)

	-- Kirim pembaruan ke client
	if newTotal then
		CoinsUpdateEvent:FireClient(player, newTotal)
	end

	return newTotal
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