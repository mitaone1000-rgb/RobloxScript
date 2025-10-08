-- RandomWeaponManager.lua (Script)
-- Path: ServerScriptService/Script/RandomWeaponManager.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local RandomConfig = require(ModuleScriptServerScriptService:WaitForChild("RandomWeaponConfig"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local CoinsManager = require(ModuleScriptServerScriptService:WaitForChild("CoinsModule"))

local openReplaceUI = RemoteEvents:WaitForChild("OpenReplaceUI")   
local replaceChoiceEv = RemoteEvents:WaitForChild("ReplaceChoice")  

local purchaseRF = RemoteFunctions:WaitForChild("PurchaseRandomWeapon") 

-- pendingOffers[player] = {weaponName = "...", cost = X, timestamp = tick()}
local pendingOffers = {}

local function getPlayerWeapons(player)
	local weapons = {}
	local function checkContainer(container)
		if not container then return end
		for _, obj in pairs(container:GetChildren()) do
			if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
				local isTemp = obj:GetAttribute("TemporaryDrop") == true
				-- only count permanent weapons (skip temporary drops like Minigun)
				if WeaponModule.Weapons[obj.Name] and not isTemp then
					table.insert(weapons, obj)
				end
			end
		end
	end
	-- backpack and character
	checkContainer(player:FindFirstChild("Backpack"))
	if player.Character then checkContainer(player.Character) end
	return weapons
end

-- helper: find weapon template in ServerStorage
local function findWeaponTemplate(name)
	-- try folder ServerStorage.Weapons first
	local weaponsFolder = ServerStorage:FindFirstChild("Weapons")
	if weaponsFolder and weaponsFolder:FindFirstChild(name) then
		return weaponsFolder:FindFirstChild(name)
	end
	-- fallback: top-level in ServerStorage
	return ServerStorage:FindFirstChild(name)
end

-- give starter weapon on character spawn (M1911)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		-- delay kecil untuk memastikan Backpack exist
		task.wait(0.1)
		local backpack = player:FindFirstChild("Backpack")
		if not backpack then return end

		-- only give starter if player has none of starter
		local hasStarter = false
		for _, tool in pairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.Name == RandomConfig.StarterWeapon then
				hasStarter = true
				break
			end
		end
		if not hasStarter and char:FindFirstChildOfClass("Tool") == nil then
			local template = findWeaponTemplate(RandomConfig.StarterWeapon)
			if template then
				local HttpService = game:GetService("HttpService")
				local clone = template:Clone()
				clone:SetAttribute("WeaponId", HttpService:GenerateGUID(false))

				-- Set equipped skin attribute
				local inventoryData = CoinsManager.GetData(player)
				if inventoryData and inventoryData.Skins and inventoryData.Skins.Equipped then
					local equippedSkin = inventoryData.Skins.Equipped[clone.Name]
					if equippedSkin then
						clone:SetAttribute("EquippedSkin", equippedSkin)
					end
				end

				clone.Parent = player:FindFirstChild("Backpack") or player
			end
		end
	end)
end)

-- Purchase RemoteFunction
purchaseRF.OnServerInvoke = function(player)
	-- Basic checks
	if not player or not player:IsA("Player") then
		return {success=false, message="Invalid player"}
	end

	local points = PointsSystem.GetPoints(player) or 0
	if points < RandomConfig.Cost then
		return {success=false, message="Not enough points"}
	end

	-- choose random weapon name
	local pool = RandomConfig.AvailableWeapons
	if #pool == 0 then
		return {success=false, message="No weapons configured"}
	end
	local newName = pool[math.random(1,#pool)]
	local template = findWeaponTemplate(newName)
	if not template then
		return {success=false, message="Weapon template not found on server: "..newName}
	end

	-- Langsung potong BP
	PointsSystem.AddPoints(player, -RandomConfig.Cost)

	local weapons = getPlayerWeapons(player)
	if #weapons < RandomConfig.MaxWeapons then
		-- give weapon directly
		local clone = template:Clone()

		-- Set equipped skin attribute
		local inventoryData = CoinsManager.GetData(player)
		if inventoryData and inventoryData.Skins and inventoryData.Skins.Equipped then
			local equippedSkin = inventoryData.Skins.Equipped[clone.Name]
			if equippedSkin then
				clone:SetAttribute("EquippedSkin", equippedSkin)
			end
		end

		clone.Parent = player:FindFirstChild("Backpack") or player
		return {success=true, message=("Purchased %s"):format(newName), weaponName=newName, replaced=false}
	else
		-- already max weapons => ask player which one to replace
		pendingOffers[player] = {weaponName = newName, cost = RandomConfig.Cost, time = tick()}
		-- collect current weapon names
		local names = {}
		for i, w in ipairs(weapons) do
			names[i] = w.Name
		end
		-- Fire client to open replace UI
		openReplaceUI:FireClient(player, names, newName, RandomConfig.Cost)
		-- Indicate that server has requested choice — client will trigger ReplaceChoice
		return {success=false, message="choose", weaponName=newName}
	end
end

-- ReplaceChoice handler: client tells which index to replace
replaceChoiceEv.OnServerEvent:Connect(function(player, index)
	-- validate
	local offer = pendingOffers[player]
	if not offer then
		-- nothing pending
		return
	end
	-- timeout e.g. 30s
	if tick() - (offer.time or 0) > 30 then
		pendingOffers[player] = nil
		return
	end

	local weapons = getPlayerWeapons(player)
	if index < 1 or index > #weapons then
		-- invalid selection
		return
	end

	-- do replacement
	local toRemove = weapons[index]
	-- prevent replacing temporary drop (e.g., Minigun from drop)
	if toRemove and toRemove:GetAttribute("TemporaryDrop") then
		return
	end
	if toRemove and toRemove.Parent then
		toRemove:Destroy()
	end

	-- clone new weapon and give to player
	local template = findWeaponTemplate(offer.weaponName)
	if template then
		local clone = template:Clone()

		-- Set equipped skin attribute
		local inventoryData = CoinsManager.GetData(player)
		if inventoryData and inventoryData.Skins and inventoryData.Skins.Equipped then
			local equippedSkin = inventoryData.Skins.Equipped[clone.Name]
			if equippedSkin then
				clone:SetAttribute("EquippedSkin", equippedSkin)
			end
		end

		clone.Parent = player:FindFirstChild("Backpack") or player
		-- Auto-equip senjata baru setelah replace
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and clone and clone.Parent then
				hum:EquipTool(clone)
			end
		end
	end

	-- clear pending
	pendingOffers[player] = nil
end)

-- cleanup pendingOffers on leave
Players.PlayerRemoving:Connect(function(player)
	pendingOffers[player] = nil
end)
