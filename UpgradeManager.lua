-- UpgradeManager.lua (Script)
-- Path: ServerScriptService/Script/UpgradeManager.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local WeaponUpgradeModule = require(ModuleScriptServerScriptService:WaitForChild("WeaponUpgradeConfigModule"))

local upgradeEvent = RemoteEvents:WaitForChild("UpgradeUIOpen")
local confirmUpgradeEvent = RemoteEvents:WaitForChild("ConfirmUpgrade")

local upgradeRF = RemoteFunctions:WaitForChild("UpgradeWeaponRF")
local getLevelRF = RemoteFunctions:WaitForChild("GetWeaponLevelRF")

local DefaultConfig = {
	BaseCost = 100,
	CostMultiplier = 1.6,
	CostExpo = 1.35,
	DamagePerLevel = 5,
	MaxLevel = 10
}

-- Helper: apply skin based on level (server-side)
local function mergeConfig(base, override)
	local out = {}
	for k, v in pairs(base) do
		out[k] = v
	end
	if override then
		for k, v in pairs(override) do
			out[k] = v
		end
	end
	return out
end

-- Ubah radius menjadi 5 studs
local function isNearUpgradePart(player)
	local part = workspace:FindFirstChild("Upgrade")
	if not part or not part:IsA("BasePart") then
		return false
	end
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		return false
	end
	local dist = (char.HumanoidRootPart.Position - part.Position).Magnitude
	return dist <= 5  -- Diubah dari 8 menjadi 5
end

getLevelRF.OnServerInvoke = function(player, tool)
	if not player or not player:IsA("Player") then
		return 0
	end
	if not tool or not tool:IsA("Tool") then
		return 0
	end
	local weaponId = tool:GetAttribute("WeaponId")
	local level = WeaponUpgradeModule.GetLevel(player, weaponId) or 0
	tool:SetAttribute("UpgradeLevel", level)
	return level
end

-- Sekarang upgradeRF hanya mengembalikan informasi biaya dan level, tidak langsung mengupgrade
upgradeRF.OnServerInvoke = function(player, tool)
	if not player or not player:IsA("Player") then
		return { success = false, message = "Invalid player" }
	end
	if not tool or not tool:IsA("Tool") then
		return { success = false, message = "Tool tidak valid" }
	end
	if not isNearUpgradePart(player) then
		return { success = false, message = "Far from station upgrade" }
	end

	local backpack = player:FindFirstChild("Backpack")
	local owns = false
	if player.Character and tool:IsDescendantOf(player.Character) then
		owns = true
	end
	if backpack and tool:IsDescendantOf(backpack) then
		owns = true
	end
	if not owns then
		return { success = false, message = "Kamu tidak memiliki senjata ini" }
	end

	local weaponName = tool.Name
	local weaponId = tool:GetAttribute("WeaponId")
	local weaponDef = WeaponModule.Weapons[weaponName]
	if not weaponDef then
		return { success = false, message = "Def senjata tidak ditemukan" }
	end

	local currentLevel = WeaponUpgradeModule.GetLevel(player, weaponId) or 0
	local nextLevel = currentLevel + 1

	local cfg = DefaultConfig
	if weaponDef.UpgradeConfig then
		cfg = mergeConfig(DefaultConfig, weaponDef.UpgradeConfig)
	end

	if nextLevel > cfg.MaxLevel then
		return { success = false, message = "Sudah level maksimal" }
	end

	local cost = WeaponUpgradeModule.CalculateCost(weaponName, nextLevel)
	local points = PointsSystem.GetPoints(player) or 0
	if points < cost then
		return { success = false, message = "Tidak cukup poin" }
	end

	-- Kembalikan informasi upgrade, tidak langsung upgrade
	return {
		success = true,
		weaponName = weaponName,
		currentLevel = currentLevel,
		nextLevel = nextLevel,
		cost = cost,
		message = "Konfirmasi upgrade?"
	}
end

-- Event untuk konfirmasi upgrade dari client
confirmUpgradeEvent.OnServerEvent:Connect(function(player, tool, confirm)
	if not confirm then return end

	-- Ulangi pengecekan keamanan
	if not player or not player:IsA("Player") then return end
	if not tool or not tool:IsA("Tool") then return end
	if not isNearUpgradePart(player) then return end

	local backpack = player:FindFirstChild("Backpack")
	local owns = false
	if player.Character and tool:IsDescendantOf(player.Character) then
		owns = true
	end
	if backpack and tool:IsDescendantOf(backpack) then
		owns = true
	end
	if not owns then return end

	local weaponName = tool.Name
	local weaponId = tool:GetAttribute("WeaponId")
	local weaponDef = WeaponModule.Weapons[weaponName]
	if not weaponDef then return end

	local currentLevel = WeaponUpgradeModule.GetLevel(player, weaponId) or 0
	local nextLevel = currentLevel + 1

	local cfg = DefaultConfig
	if weaponDef.UpgradeConfig then
		cfg = mergeConfig(DefaultConfig, weaponDef.UpgradeConfig)
	end

	if nextLevel > cfg.MaxLevel then return end

	local cost = WeaponUpgradeModule.CalculateCost(weaponName, nextLevel)
	local points = PointsSystem.GetPoints(player) or 0
	if points < cost then return end

	local ok, _, newLevel, _ = WeaponUpgradeModule.AttemptUpgrade(player, weaponId, weaponName)
	if ok then
		tool:SetAttribute("UpgradeLevel", newLevel)

		-- Jika upgrade dari level 0 ke 1, tambahkan ammo
		if currentLevel == 0 and newLevel == 1 then
			local mult = 1.5 -- 50% naik
			local oldMax = weaponDef.MaxAmmo or 0
			local oldReserve = weaponDef.ReserveAmmo or 0

			local newMax = math.floor(oldMax * mult + 0.5)
			local newReserve = math.floor(oldReserve * mult + 0.5)

			tool:SetAttribute("CustomMaxAmmo", newMax)
			tool:SetAttribute("CustomReserveAmmo", newReserve)
		end

		upgradeEvent:FireClient(player, weaponName, newLevel)
	end
end)