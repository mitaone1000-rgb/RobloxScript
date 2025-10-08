-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Deskripsi: Mengelola UI inventaris skin secara mandiri, termasuk tombol pembukanya.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Module & Event References
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local inventoryRemote = ReplicatedStorage:WaitForChild("GetInventoryData")
local skinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SkinManagementEvent")

-- UI Elements
local inventoryScreenGui = Instance.new("ScreenGui")
inventoryScreenGui.Name = "InventoryScreenGui"
inventoryScreenGui.Enabled = true -- Selalu aktif untuk menampilkan tombol
inventoryScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Tombol untuk membuka inventaris
local inventoryButton = Instance.new("TextButton")
inventoryButton.Name = "InventoryButton"
inventoryButton.Parent = inventoryScreenGui
inventoryButton.Size = UDim2.new(0, 150, 0, 50)
inventoryButton.Position = UDim2.new(0.5, -75, 0.85, 0)
inventoryButton.Text = "Inventory"
inventoryButton.Font = Enum.Font.SourceSansBold
inventoryButton.TextSize = 20
inventoryButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
inventoryButton.TextColor3 = Color3.new(1, 1, 1)
local btnCorner = Instance.new("UICorner", inventoryButton)
btnCorner.CornerRadius = UDim.new(0, 8)

-- Frame utama inventaris (awalnya tidak terlihat)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = inventoryScreenGui
mainFrame.Size = UDim2.new(0, 500, 0, 350)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = false -- Awalnya disembunyikan

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = mainFrame

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 50)
title.Text = "Inventory"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
local titleCorner = Instance.new("UICorner", title)
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local backButton = Instance.new("TextButton", mainFrame)
backButton.Size = UDim2.new(0, 50, 0, 30)
backButton.Position = UDim2.new(0, 10, 0, 10)
backButton.Text = "Back"
backButton.Font = Enum.Font.SourceSans
backButton.TextSize = 16
backButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
backButton.TextColor3 = Color3.new(1, 1, 1)
local backCorner = Instance.new("UICorner", backButton)
backCorner.CornerRadius = UDim.new(0, 6)

-- Weapon List (Left Side)
local weaponListFrame = Instance.new("ScrollingFrame", mainFrame)
weaponListFrame.Size = UDim2.new(0.4, -15, 1, -60)
weaponListFrame.Position = UDim2.new(0, 10, 0, 50)
weaponListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
local wl_layout = Instance.new("UIListLayout", weaponListFrame)
wl_layout.Padding = UDim.new(0, 5)
wl_layout.SortOrder = Enum.SortOrder.Name

-- Skin List (Right Side)
local skinListFrame = Instance.new("ScrollingFrame", mainFrame)
skinListFrame.Size = UDim2.new(0.6, -15, 1, -110)
skinListFrame.Position = UDim2.new(0.4, 0, 0, 50)
skinListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
local sl_layout = Instance.new("UIGridLayout", skinListFrame)
sl_layout.CellPadding = UDim2.new(0, 5, 0, 5)
sl_layout.CellSize = UDim2.new(0, 100, 0, 120)

-- Equip Button
local equipButton = Instance.new("TextButton", mainFrame)
equipButton.Size = UDim2.new(0.6, -15, 0, 40)
equipButton.Position = UDim2.new(0.4, 0, 1, -50)
equipButton.Text = "Equip Skin"
equipButton.Font = Enum.Font.SourceSansBold
equipButton.TextSize = 18
equipButton.BackgroundColor3 = Color3.fromRGB(130, 130, 130) -- Disabled
equipButton.TextColor3 = Color3.new(1, 1, 1)
local equipCorner = Instance.new("UICorner", equipButton)
equipCorner.CornerRadius = UDim.new(0, 8)
equipButton.AutoButtonColor = false

-- State variables
local inventoryData = nil
local selectedWeapon = nil
local selectedSkin = nil

local function updateSkinList()
	for _, child in ipairs(skinListFrame:GetChildren()) do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
	selectedSkin = nil
	equipButton.AutoButtonColor = false
	equipButton.BackgroundColor3 = Color3.fromRGB(130, 130, 130)

	if not selectedWeapon or not inventoryData then return end

	local ownedSkins = inventoryData.Skins.Owned[selectedWeapon]
	local equippedSkin = inventoryData.Skins.Equipped[selectedWeapon]

	for _, skinName in ipairs(ownedSkins) do
		local skinButton = Instance.new("TextButton")
		skinButton.Name = skinName
		skinButton.LayoutOrder = (skinName == equippedSkin) and 0 or 1
		skinButton.Size = UDim2.new(0, 100, 0, 120)
		skinButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
		skinButton.Parent = skinListFrame

		local skinLabel = Instance.new("TextLabel", skinButton)
		skinLabel.Size = UDim2.new(1, 0, 0, 20)
		skinLabel.Position = UDim2.new(0, 0, 1, -20)
		skinLabel.Text = skinName
		skinLabel.Font = Enum.Font.SourceSans
		skinLabel.TextSize = 14
		skinLabel.TextColor3 = Color3.new(1, 1, 1)
		skinLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

		if skinName == equippedSkin then
			skinButton.BackgroundColor3 = Color3.fromRGB(0, 170, 81)
		end

		skinButton.MouseButton1Click:Connect(function()
			selectedSkin = skinName
			for _, btn in ipairs(skinListFrame:GetChildren()) do
				if btn:IsA("TextButton") then
					if inventoryData.Skins.Equipped[selectedWeapon] == btn.Name then
						btn.BackgroundColor3 = Color3.fromRGB(0, 170, 81)
					else
						btn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
					end
				end
			end
			skinButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)

			if selectedSkin ~= equippedSkin then
				equipButton.AutoButtonColor = true
				equipButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
			else
				equipButton.AutoButtonColor = false
				equipButton.BackgroundColor3 = Color3.fromRGB(130, 130, 130)
			end
		end)
	end
end

local function updateWeaponList()
	for _, child in ipairs(weaponListFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local weaponNames = {}
	for name, _ in pairs(WeaponModule.Weapons) do
		table.insert(weaponNames, name)
	end
	table.sort(weaponNames)

	for _, weaponName in ipairs(weaponNames) do
		local weaponButton = Instance.new("TextButton")
		weaponButton.Name = weaponName
		weaponButton.Size = UDim2.new(1, -10, 0, 40)
		weaponButton.Text = weaponName
		weaponButton.Font = Enum.Font.SourceSans
		weaponButton.TextSize = 16
		weaponButton.TextColor3 = Color3.new(1, 1, 1)
		weaponButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
		weaponButton.Parent = weaponListFrame

		weaponButton.MouseButton1Click:Connect(function()
			selectedWeapon = weaponName
			for _, btn in ipairs(weaponListFrame:GetChildren()) do
				if btn:IsA("TextButton") then
					btn.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
				end
			end
			weaponButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
			updateSkinList()
		end)
	end
end

-- Tombol untuk membuka menu inventaris
inventoryButton.MouseButton1Click:Connect(function()
	if not inventoryData then
		inventoryData = inventoryRemote:InvokeServer()
	end
	updateWeaponList()
	updateSkinList()

	inventoryButton.Visible = false
	mainFrame.Visible = true
end)

-- Tombol untuk kembali dari menu inventaris
backButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	inventoryButton.Visible = true
end)

-- Tombol untuk memasang skin
equipButton.MouseButton1Click:Connect(function()
	if not equipButton.AutoButtonColor then return end

	if selectedWeapon and selectedSkin then
		skinEvent:FireServer("EquipSkin", selectedWeapon, selectedSkin)
		inventoryData.Skins.Equipped[selectedWeapon] = selectedSkin
		updateSkinList()
	end
end)