-- GachaModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GachaModule.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul yang diperlukan
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local GachaConfig = require(ServerScriptService.ModuleScript:WaitForChild("GachaConfig"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

local GachaModule = {}

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
-- Fungsi internal untuk satu kali roll, digunakan oleh Roll dan RollMultiple
local function performSingleRoll(player, playerData)
	-- 1. Logika Pity
	playerData.PityCount = (playerData.PityCount or 0) + 1
	local isPityTriggered = playerData.PityCount >= GachaConfig.PITY_THRESHOLD

	-- 2. Tentukan hadiah berdasarkan peluang
	local randomNumber = math.random(1, 100)
	local chosenRarity

	if isPityTriggered or randomNumber <= GachaConfig.RARITY_CHANCES.Legendary then
		chosenRarity = "Legendary"
	else
		chosenRarity = "Common"
	end

	-- 3. Proses hadiah berdasarkan kelangkaan
	local availableSkins = getAvailableSkins(player)

	if chosenRarity == "Legendary" and #availableSkins == 0 then
		chosenRarity = "Common"
	end

	if chosenRarity == "Legendary" then
		playerData.PityCount = 0 -- Reset pity
		local randomSkinIndex = math.random(1, #availableSkins)
		local prize = availableSkins[randomSkinIndex]
		CoinsManager.AddSkin(player, prize.Weapon, prize.Skin)
		GachaSkinWonEvent:FireAllClients(player, prize.Skin)
		return { Type = "Skin", WeaponName = prize.Weapon, SkinName = prize.Skin }
	else
		local prizeAmount = math.random(GachaConfig.COMMON_REWARD_RANGE.Min, GachaConfig.COMMON_REWARD_RANGE.Max)
		CoinsManager.AddCoins(player, prizeAmount)
		return { Type = "Coins", Amount = prizeAmount }
	end
end

function GachaModule.Roll(player)
	local playerData = CoinsManager.GetData(player)

	if playerData.Coins < GachaConfig.GACHA_COST then
		return { Success = false, Message = "BloodCoins tidak cukup." }
	end

	if not CoinsManager.SubtractCoins(player, GachaConfig.GACHA_COST) then
		return { Success = false, Message = "Gagal mengurangi BloodCoins." }
	end

	local prize = performSingleRoll(player, playerData)
	CoinsManager.UpdatePityCount(player, playerData.PityCount)

	return { Success = true, Prize = prize }
end

function GachaModule.RollMultiple(player)
	local playerData = CoinsManager.GetData(player)
	local totalCost = GachaConfig.GACHA_COST * GachaConfig.MULTI_ROLL_COST_MULTIPLIER

	if playerData.Coins < totalCost then
		return { Success = false, Message = "BloodCoins tidak cukup untuk 10+1 roll." }
	end

	if not CoinsManager.SubtractCoins(player, totalCost) then
		return { Success = false, Message = "Gagal mengurangi BloodCoins." }
	end

	local prizes = {}
	for i = 1, GachaConfig.MULTI_ROLL_COUNT do
		local prize = performSingleRoll(player, playerData)
		table.insert(prizes, prize)
	end

	CoinsManager.UpdatePityCount(player, playerData.PityCount)

	return { Success = true, Prizes = prizes }
end

return GachaModule
