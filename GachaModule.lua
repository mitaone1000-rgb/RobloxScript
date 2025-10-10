-- GachaModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GachaModule.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul yang diperlukan
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

local GachaModule = {}

-- Konfigurasi Gacha
local GACHA_COST = 100
local RARITY_CHANCES = {
	Legendary = 5,  -- Peluang dalam persen (5%)
	Common = 95, -- Peluang dalam persen (95%)
}
local COMMON_REWARD_RANGE = {Min = 10, Max = 50}

-- Fungsi untuk mendapatkan daftar semua skin yang *belum* dimiliki pemain
local function getAvailableSkins(player)
	local inventoryData = CoinsManager.GetData(player)
	local ownedSkins = inventoryData.Skins.Owned
	local allSkins = {}

	-- Kumpulkan semua skin dari WeaponModule, kecuali "Default Skin"
	for weaponName, weaponData in pairs(WeaponModule.Weapons) do
		for skinName, _ in pairs(weaponData.Skins) do
			if skinName ~= "Default Skin" then
				-- Cek apakah pemain sudah memiliki skin ini
				local hasSkin = false
				if ownedSkins[weaponName] then
					for _, ownedSkinName in ipairs(ownedSkins[weaponName]) do
						if ownedSkinName == skinName then
							hasSkin = true
							break
						end
					end
				end

				-- Jika belum dimiliki, tambahkan ke daftar
				if not hasSkin then
					table.insert(allSkins, {Weapon = weaponName, Skin = skinName})
				end
			end
		end
	end

	return allSkins
end

-- RemoteEvent untuk pengumuman global
local GachaSkinWonEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("GachaSkinWonEvent")
if not GachaSkinWonEvent then
	GachaSkinWonEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	GachaSkinWonEvent.Name = "GachaSkinWonEvent"
end

-- Fungsi inti untuk melakukan roll gacha
function GachaModule.Roll(player)
	local playerData = CoinsManager.GetData(player)

	-- 1. Validasi: Cek apakah koin cukup
	if playerData.Coins < GACHA_COST then
		return {Success = false, Message = "BloodCoins tidak cukup."}
	end

	-- 2. Kurangi koin pemain
	local success = CoinsManager.SubtractCoins(player, GACHA_COST)
	if not success then
		return {Success = false, Message = "Gagal mengurangi BloodCoins."}
	end

	-- 3. Tentukan hadiah berdasarkan peluang
	local randomNumber = math.random(1, 100)
	local chosenRarity

	if randomNumber <= RARITY_CHANCES.Legendary then
		chosenRarity = "Legendary"
	else
		chosenRarity = "Common"
	end

	-- 4. Proses hadiah berdasarkan kelangkaan
	local availableSkins = getAvailableSkins(player)

	-- Jika pemain memilih Legendary TAPI sudah punya semua skin, beri hadiah Common
	if chosenRarity == "Legendary" and #availableSkins == 0 then
		chosenRarity = "Common"
	end

	if chosenRarity == "Legendary" then
		-- Beri hadiah skin
		local randomSkinIndex = math.random(1, #availableSkins)
		local prize = availableSkins[randomSkinIndex]

		CoinsManager.AddSkin(player, prize.Weapon, prize.Skin)

		-- Kirim pengumuman global
		GachaSkinWonEvent:FireAllClients(player, prize.Skin)

		return {
			Success = true,
			Prize = {
				Type = "Skin",
				WeaponName = prize.Weapon,
				SkinName = prize.Skin
			}
		}
	else
		-- Beri hadiah koin
		local prizeAmount = math.random(COMMON_REWARD_RANGE.Min, COMMON_REWARD_RANGE.Max)
		CoinsManager.AddCoins(player, prizeAmount)

		return {
			Success = true,
			Prize = {
				Type = "Coins",
				Amount = prizeAmount
			}
		}
	end
end

return GachaModule
