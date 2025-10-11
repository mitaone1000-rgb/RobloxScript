-- CoinsModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/CoinsModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))
local StatsModule = require(ServerScriptService.ModuleScript:WaitForChild("StatsModule"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

-- RemoteEvent untuk pembaruan di sisi client
local CoinsUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("CoinsUpdateEvent")
if not CoinsUpdateEvent then
	CoinsUpdateEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	CoinsUpdateEvent.Name = "CoinsUpdateEvent"
end

local CoinsManager = {}
local NEW_SCOPE = "Inventory"
local OLD_SCOPE = "Coins"
-- Data default tidak perlu diisi skin, karena akan di-generate oleh GetData
local DEFAULT_DATA = {
	Coins = 0,
	Skins = {
		Owned = {},
		Equipped = {}
	},
	PityCount = 0
}

-- Fungsi untuk mendapatkan data inventaris pemain (mengembalikan tabel)
function CoinsManager.GetData(player)
	local data = DataStoreManager.GetData(player, NEW_SCOPE)
	local needsSave = false

	-- Penanganan data korup atau lama: jika data adalah angka (hanya koin).
	if type(data) == "number" then
		data = {Coins = data}
		needsSave = true
	end

	-- Jika pemain tidak punya data sama sekali.
	if data == nil then
		needsSave = true
		-- Coba migrasi dari scope "Coins" yang lama.
		local oldData = DataStoreManager.GetData(player, OLD_SCOPE)
		if oldData ~= nil and type(oldData) == "number" then
			-- Data lama ditemukan, bungkus dalam format baru.
			data = {Coins = oldData}
			DataStoreManager.RemoveDataByUserId(player.UserId, OLD_SCOPE) -- Hapus data lama.
		else
			-- Jika tidak ada data sama sekali, ini pemain baru. Buat data dari nol.
			data = {
				Coins = 0,
				Skins = {
					Owned = {},
					Equipped = {}
				}
			}
		end
	end

	-- Pastikan struktur Skins ada untuk data lama atau yang baru dibuat.
	if not data.Skins then
		data.Skins = {
			Owned = {},
			Equipped = {}
		}
		needsSave = true
	end

	-- Pastikan PityCount ada
	if data.PityCount == nil then
		data.PityCount = 0
		needsSave = true
	end

	-- Iterasi semua senjata untuk memastikan pemain punya skin default.
	local weaponConfig = WeaponModule.Weapons
	for weaponName, _ in pairs(weaponConfig) do
		-- Jika pemain belum punya daftar skin untuk senjata ini, buatkan.
		if not data.Skins.Owned[weaponName] then
			data.Skins.Owned[weaponName] = {"Default Skin"}
			needsSave = true
		end
		-- Jika pemain belum punya skin yang terpasang untuk senjata ini, pasang default.
		if not data.Skins.Equipped[weaponName] then
			data.Skins.Equipped[weaponName] = "Default Skin"
			needsSave = true
		end
	end

	-- Simpan data jika ada perubahan (pemain baru, migrasi, atau perbaikan struktur).
	if needsSave then
		DataStoreManager.SaveData(player, NEW_SCOPE, data)
	end

	return data
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

-- Fungsi untuk mengurangi koin
function CoinsManager.SubtractCoins(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return false end

	local data = CoinsManager.GetData(player)
	if data.Coins < amount then
		return false -- Koin tidak cukup
	end

	data.Coins = data.Coins - amount
	DataStoreManager.SaveData(player, NEW_SCOPE, data)

	-- Kirim pembaruan ke client
	CoinsUpdateEvent:FireClient(player, data.Coins)
	return true -- Pengurangan berhasil
end

-- Fungsi untuk menambahkan skin ke inventaris pemain
function CoinsManager.AddSkin(player, weaponName, skinName)
	if not player or not weaponName or not skinName then return false end

	local data = CoinsManager.GetData(player)
	if not data.Skins.Owned[weaponName] then
		-- Ini seharusnya tidak terjadi karena GetData() menginisialisasi semua senjata
		-- Tapi sebagai pengaman, kita bisa buat tabelnya di sini
		data.Skins.Owned[weaponName] = {"Default Skin"}
	end

	-- Cek apakah skin sudah dimiliki
	if table.find(data.Skins.Owned[weaponName], skinName) then
		return false -- Skin sudah dimiliki
	end

	-- Tambahkan skin baru dan simpan
	table.insert(data.Skins.Owned[weaponName], skinName)
	DataStoreManager.SaveData(player, NEW_SCOPE, data)

	return true -- Berhasil menambahkan skin
end

-- Fungsi untuk memperbarui PityCount
function CoinsManager.UpdatePityCount(player, newCount)
	if not player or type(newCount) ~= "number" then return false end

	local data = CoinsManager.GetData(player)
	data.PityCount = newCount
	DataStoreManager.SaveData(player, NEW_SCOPE, data)
	return true
end

-- Fungsi untuk mendapatkan data koin berdasarkan UserID (untuk admin, mengembalikan tabel)
function CoinsManager.GetDataByUserId(userId)
	local data = DataStoreManager.GetDataByUserId(userId, NEW_SCOPE)

	-- Penanganan data korup atau lama: jika data adalah angka (hanya koin).
	if type(data) == "number" then
		data = {Coins = data}
	end

	-- Jika pemain tidak punya data sama sekali.
	if data == nil then
		-- Coba migrasi dari scope "Coins" yang lama.
		local oldData = DataStoreManager.GetDataByUserId(userId, OLD_SCOPE)
		if oldData ~= nil and type(oldData) == "number" then
			data = {Coins = oldData}
		else
			-- Buat data default sementara jika tidak ada data.
			data = {
				Coins = 0,
				Skins = {
					Owned = {},
					Equipped = {}
				}
			}
		end
	end

	-- Pastikan struktur Skins ada untuk data lama atau yang baru dibuat.
	if not data.Skins then
		data.Skins = {
			Owned = {},
			Equipped = {}
		}
	end

	-- Iterasi semua senjata untuk memastikan data yang dikembalikan lengkap.
	local weaponConfig = WeaponModule.Weapons
	for weaponName, _ in pairs(weaponConfig) do
		if not data.Skins.Owned[weaponName] then
			data.Skins.Owned[weaponName] = {"Default Skin"}
		end
		if not data.Skins.Equipped[weaponName] then
			data.Skins.Equipped[weaponName] = "Default Skin"
		end
	end

	return data
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
