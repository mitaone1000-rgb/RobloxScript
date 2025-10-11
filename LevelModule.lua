-- LevelModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/LevelModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul DataStoreManager
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

local LevelManager = {}
local NEW_SCOPE = "Stats"
local OLD_SCOPE = "Level"

-- Konfigurasi: XP yang dibutuhkan per level
local XP_PER_LEVEL = 1000
local DEFAULT_DATA = {
    Level = 1,
    XP = 0,
    SkillPoints = 0,
    Skills = {
        DamageHeadshot = 0
    }
}

-- Fungsi untuk mendapatkan data pemain
function LevelManager.GetData(player)
	local data = DataStoreManager.GetData(player, NEW_SCOPE)

	-- Jika tidak ada data, coba migrasi dari scope level lama
	if data == nil then
		local oldLevelData = DataStoreManager.GetData(player, OLD_SCOPE)
		if oldLevelData ~= nil then
			data = oldLevelData
			-- Hapus data level lama setelah digabungkan
			DataStoreManager.RemoveDataByUserId(player.UserId, OLD_SCOPE)
		end
	end

	-- Cek apakah ada data skill lama yang perlu dimigrasikan
	local oldSkillData = DataStoreManager.GetData(player, "SkillTree")
	if oldSkillData then
		data = data or DEFAULT_DATA -- Pastikan 'data' ada isinya
		-- Gabungkan data skill ke data stats
		data.SkillPoints = oldSkillData.SkillPoints or 0
		data.Skills = oldSkillData.Skills or { DamageHeadshot = 0 }

		-- Hapus data skill lama setelah digabungkan
		DataStoreManager.RemoveDataByUserId(player.UserId, "SkillTree")

		-- Simpan data yang sudah digabung
		DataStoreManager.SaveData(player, NEW_SCOPE, data)
	end

	-- Inisialisasi skill jika belum ada di data pemain
	if data and data.Skills == nil then
		data.Skills = { DamageHeadshot = 0 }
		data.SkillPoints = data.SkillPoints or 0
	end

	return data or DEFAULT_DATA
end

-- Fungsi untuk mendapatkan data pemain berdasarkan UserID (untuk admin)
function LevelManager.GetDataByUserId(userId)
	local data = DataStoreManager.GetDataByUserId(userId, NEW_SCOPE)
	if data == nil then
		-- Coba migrasi dari scope lama
		local oldData = DataStoreManager.GetDataByUserId(userId, OLD_SCOPE)
		if oldData ~= nil then
			-- Data ditemukan di scope lama, migrasikan
			DataStoreManager.SaveDataByUserId(userId, NEW_SCOPE, oldData)
			DataStoreManager.RemoveDataByUserId(userId, OLD_SCOPE)
			return oldData
		end
	end
	return data or DEFAULT_DATA
end

-- Fungsi untuk mengubah data pemain berdasarkan UserID (untuk admin)
function LevelManager.SetData(userId, newData)
	if not userId or not newData or type(newData.Level) ~= "number" or type(newData.XP) ~= "number" then
		return false, "Invalid arguments or data format"
	end
	return DataStoreManager.SaveDataByUserId(userId, NEW_SCOPE, newData)
end

-- Fungsi untuk menghapus data pemain berdasarkan UserID (untuk admin)
function LevelManager.DeleteData(userId)
	-- Hapus dari kedua scope untuk memastikan kebersihan data
	DataStoreManager.RemoveDataByUserId(userId, OLD_SCOPE)
	return DataStoreManager.RemoveDataByUserId(userId, NEW_SCOPE)
end

-- Fungsi untuk menambahkan XP
function LevelManager.AddXP(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end

	local data = LevelManager.GetData(player)
	data.XP = data.XP + amount

	local hasLeveledUp = false
	-- Cek kenaikan level
	while data.XP >= XP_PER_LEVEL do
		data.XP = data.XP - XP_PER_LEVEL
		data.Level = data.Level + 1
		data.SkillPoints = (data.SkillPoints or 0) + 1
		hasLeveledUp = true
		-- Di sini Anda bisa menambahkan event untuk notifikasi level up
	end

	-- Simpan data melalui DataStoreManager
	DataStoreManager.SaveData(player, NEW_SCOPE, data)

	-- Kirim update ke client
	local LevelUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("LevelUpdateEvent")
	if LevelUpdateEvent then
		LevelUpdateEvent:FireClient(player, data.Level, data.XP, XP_PER_LEVEL)
	end

	-- Kirim update data skill tree HANYA jika pemain naik level
	if hasLeveledUp then
		local SkillDataUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("SkillDataUpdateEvent")
		if SkillDataUpdateEvent then
			SkillDataUpdateEvent:FireClient(player, data)
		end
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
