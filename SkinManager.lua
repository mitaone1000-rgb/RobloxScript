-- SkinManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/SkinManager.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Memuat modul yang diperlukan
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

local SkinManager = {}

-- Fungsi untuk mendapatkan skin yang sedang dipakai pemain untuk senjata tertentu
function SkinManager.GetEquippedSkin(player, weaponName)
	if not player or not weaponName then return nil end

	local inventoryData = CoinsManager.GetData(player)
	if inventoryData and inventoryData.Skins and inventoryData.Skins.Equipped then
		return inventoryData.Skins.Equipped[weaponName]
	end

	return nil
end

-- Fungsi untuk mengganti skin yang dipakai pemain
function SkinManager.EquipSkin(player, weaponName, skinName)
	if not player or not weaponName or not skinName then
		return {Success = false, Message = "Argumen tidak valid."}
	end

	local inventoryData = CoinsManager.GetData(player)
	local weaponConfig = WeaponModule.Weapons[weaponName]

	-- Validasi 1: Apakah senjata ada di konfigurasi?
	if not weaponConfig then
		return {Success = false, Message = "Senjata tidak ditemukan: " .. weaponName}
	end

	-- Validasi 2: Apakah skin ada di konfigurasi untuk senjata ini?
	if not weaponConfig.Skins[skinName] then
		return {Success = false, Message = "Skin tidak ditemukan untuk senjata ini: " .. skinName}
	end

	-- Validasi 3: Apakah pemain memiliki skin ini?
	local ownedSkins = inventoryData.Skins.Owned[weaponName]
	if not table.find(ownedSkins, skinName) then
		return {Success = false, Message = "Anda tidak memiliki skin ini."}
	end

	-- Semua validasi lolos, ganti skin yang dipakai
	inventoryData.Skins.Equipped[weaponName] = skinName

	-- Simpan perubahan ke DataStore
	DataStoreManager.SaveData(player, "Inventory", inventoryData)

	print(player.Name .. " berhasil menggunakan skin '" .. skinName .. "' untuk senjata '" .. weaponName .. "'.")
	return {Success = true, Message = "Skin berhasil digunakan!"}
end

return SkinManager
