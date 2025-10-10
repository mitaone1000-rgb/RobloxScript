-- GachaShopSpawner.lua (Script)
-- Path: ServerScriptService/Script/GachaShopSpawner.lua
-- Script Place: Lobby

local Workspace = game:GetService("Workspace")
local gachaPart = Workspace:FindFirstChild("GachaShopSkin")

-- Buat part hanya jika belum ada
local gachaShopPart = Workspace:FindFirstChild("GachaShopSkin")
if not gachaShopPart then
	gachaShopPart = Instance.new("Part")
	gachaShopPart.Name = "GachaShopSkin"
	gachaShopPart.Size = Vector3.new(5, 1, 5)
	gachaShopPart.Position = gachaPart
	gachaShopPart.Anchored = true
	gachaShopPart.CanCollide = false
	gachaShopPart.BrickColor = BrickColor.new("Magenta")
	gachaShopPart.Parent = Workspace

	-- Buat ProximityPrompt
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.ActionText = "Buka Gacha Skin"
	proximityPrompt.ObjectText = "Toko Gacha"
	proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.MaxActivationDistance = 10
	proximityPrompt.Parent = gachaShopPart

	print("GachaShopSkin part created in Workspace.")
else
	print("GachaShopSkin part already exists.")
end
