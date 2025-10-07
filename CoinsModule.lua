-- CoinsModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/CoinsModule.lua
-- Script Place: Lobby & ACT 1: Village

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Menggunakan DataStore "Player_dev" dengan scope "Coins" sesuai permintaan
local coinsStore = DataStoreService:GetDataStore("Player_dev", "Coins")

-- RemoteEvent untuk pembaruan di sisi client
local CoinsUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("CoinsUpdateEvent")
if not CoinsUpdateEvent then
	CoinsUpdateEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	CoinsUpdateEvent.Name = "CoinsUpdateEvent"
end

local CoinsManager = {}

-- Tabel lokal untuk menyimpan cache data koin pemain
local playerCoinsCache = {}

-- Debounce untuk mencegah penyimpanan data yang berlebihan
local saveDebounce = {}

-- Fungsi untuk mendapatkan data koin pemain
function CoinsManager.GetData(player)
	if playerCoinsCache[player] then
		return playerCoinsCache[player]
	end

	local success, coins = pcall(function()
		-- Data disimpan sebagai angka langsung, bukan tabel
		return coinsStore:GetAsync("Player_" .. player.UserId)
	end)

	if success then
		local currentCoins = (type(coins) == "number") and coins or 0
		playerCoinsCache[player] = currentCoins
		return currentCoins
	else
		warn("CoinsManager: Gagal memuat data koin untuk " .. player.Name .. ". Error: " .. tostring(coins))
		playerCoinsCache[player] = 0 -- Default ke 0 jika gagal
		return 0
	end
end

-- Fungsi untuk menyimpan data koin pemain
function CoinsManager.SaveData(player)
	local coinsToSave = playerCoinsCache[player]
	if not player or type(coinsToSave) ~= "number" then return end

	-- Cek debounce
	if saveDebounce[player] then return end
	saveDebounce[player] = true

	local success, err = pcall(function()
		coinsStore:SetAsync("Player_" .. player.UserId, coinsToSave)
	end)

	if not success then
		warn("CoinsManager: Gagal menyimpan data koin untuk " .. player.Name .. ". Error: " .. tostring(err))
	end

	-- Hapus debounce setelah 5 detik
	task.delay(5, function()
		saveDebounce[player] = nil
	end)
end

-- Fungsi untuk menambahkan koin
function CoinsManager.AddCoins(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end

	local currentCoins = CoinsManager.GetData(player)
	playerCoinsCache[player] = currentCoins + amount

	-- Kirim pembaruan ke client
	CoinsUpdateEvent:FireClient(player, playerCoinsCache[player])

	return playerCoinsCache[player]
end

-- Setup saat pemain bergabung
Players.PlayerAdded:Connect(function(player)
	-- Muat data koin saat pemain masuk untuk mengisi cache
	local coins = CoinsManager.GetData(player)

	-- Kirim data awal ke client saat sudah siap
	CoinsUpdateEvent:FireClient(player, coins)
end)

-- Simpan data saat pemain keluar
Players.PlayerRemoving:Connect(function(player)
	if playerCoinsCache[player] ~= nil then
		CoinsManager.SaveData(player)
		playerCoinsCache[player] = nil -- Hapus dari cache
	end
end)

return CoinsManager
