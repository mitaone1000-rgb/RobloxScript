-- LevelManager.lua
-- Path: ServerScriptService/ModuleScript/LevelManager.lua
-- Script Place: Lobby, ACT 1: Village

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Gunakan scope "dev" untuk DataStore
local levelStore = DataStoreService:GetDataStore("PlayerLevels_dev")

local LevelManager = {}

-- Konfigurasi: XP yang dibutuhkan per level (bisa diperluas)
local XP_PER_LEVEL = 1000

-- Debounce untuk mencegah penyimpanan data yang berlebihan
local saveDebounce = {}

-- Fungsi untuk mendapatkan data pemain
function LevelManager.GetData(player)
	local success, data = pcall(function()
		return levelStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		return data
	else
		warn("LevelManager: Gagal memuat data untuk " .. player.Name .. ". Error: " .. tostring(data))
		-- Data default jika gagal memuat
		return { Level = 1, XP = 0 }
	end
end

-- Fungsi untuk menyimpan data pemain
function LevelManager.SaveData(player, data)
	if not player or not data then return end

	-- Cek debounce
	if saveDebounce[player] then return end
	saveDebounce[player] = true

	local success, err = pcall(function()
		levelStore:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn("LevelManager: Gagal menyimpan data untuk " .. player.Name .. ". Error: " .. tostring(err))
	end

	-- Hapus debounce setelah 5 detik
	task.delay(5, function()
		saveDebounce[player] = nil
	end)
end

-- Fungsi untuk menambahkan XP
function LevelManager.AddXP(player, amount)
	if not player or amount <= 0 then return end

	local data = LevelManager.GetData(player)
	if not data then return end

	data.XP = data.XP + amount

	-- Cek kenaikan level
	while data.XP >= XP_PER_LEVEL do
		data.XP = data.XP - XP_PER_LEVEL
		data.Level = data.Level + 1
		-- Di sini Anda bisa menambahkan event untuk notifikasi level up
	end

	-- Simpan data
	LevelManager.SaveData(player, data)

	-- Kirim update ke client
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LevelUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("LevelUpdateEvent")
	if LevelUpdateEvent then
		LevelUpdateEvent:FireClient(player, data.Level, data.XP, XP_PER_LEVEL)
	end
end

-- Setup saat pemain bergabung
Players.PlayerAdded:Connect(function(player)
	local data = LevelManager.GetData(player)
	if not data then return end

	-- Kirim data awal ke client
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LevelUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("LevelUpdateEvent")
	if LevelUpdateEvent then
		LevelUpdateEvent:FireClient(player, data.Level, data.XP, XP_PER_LEVEL)
	end
end)

-- Simpan data saat pemain keluar
Players.PlayerRemoving:Connect(function(player)
	local data = LevelManager.GetData(player)
	if data then
		LevelManager.SaveData(player, data)
	end
end)

return LevelManager
