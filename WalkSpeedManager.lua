-- WalkSpeedManager.lua (Script)
-- Path: ServerScriptService/Script/WalkSpeedManager.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local DebuffManager = require(ModuleScriptServerScriptService:WaitForChild("DebuffModule"))

local DEFAULT_WALK = 16
local SPRINT_SPEED = 24 -- Kecepatan sprint standar
local RELOAD_WALK = 8

local SPRINT_ATTR = "IsSprinting"
local RELOAD_ATTR = "IsReloading"
local AIM_ATTR = "IsAiming"

local function getPlayerTool(player)
	if not player.Character then return nil end
	for _, child in ipairs(player.Character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end
	return nil
end

local function getAdsWalkSpeed(tool)
	if not tool or not tool:IsA("Tool") then return nil end
	local weaponData = WeaponModule.Weapons[tool.Name]
	return weaponData and weaponData.ADS_WalkSpeed or nil
end

local function updatePlayerSpeed(player)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local targetSpeed = DEFAULT_WALK

	-- Tentukan kecepatan dasar berdasarkan status pemain
	if char:GetAttribute(RELOAD_ATTR) then
		targetSpeed = RELOAD_WALK
	elseif char:GetAttribute(AIM_ATTR) then
		local tool = getPlayerTool(player)
		local adsSpeed = getAdsWalkSpeed(tool)
		if adsSpeed then
			targetSpeed = adsSpeed
		end
	elseif char:GetAttribute(SPRINT_ATTR) then
		targetSpeed = SPRINT_SPEED
	end

	-- Dapatkan pengganda debuff dari DebuffManager
	local debuffMultiplier = DebuffManager.GetSpeedMultiplier(player)

	-- Terapkan debuff ke kecepatan target
	targetSpeed = targetSpeed * debuffMultiplier

	-- Tetapkan kecepatan akhir ke Humanoid
	if hum.WalkSpeed ~= targetSpeed then
		hum.WalkSpeed = targetSpeed
	end
end

-- Loop untuk memperbarui kecepatan semua pemain
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerSpeed(player)
	end

end)
