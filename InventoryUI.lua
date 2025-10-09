-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Deskripsi: Mengelola UI inventaris skin secara mandiri, termasuk tombol pembukanya.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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
mainFrame.Size = UDim2.new(0, 800, 0, 500) -- Ukuran diperbesar
mainFrame.Position = UDim2.new(0.5, -400, 0.5, -250) -- Disesuaikan agar tetap di tengah
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
weaponListFrame.Size = UDim2.new(0, 200, 1, -60) -- Lebar tetap
weaponListFrame.Position = UDim2.new(0, 10, 0, 50)
weaponListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
local wl_layout = Instance.new("UIListLayout", weaponListFrame)
wl_layout.Padding = UDim.new(0, 5)
wl_layout.SortOrder = Enum.SortOrder.Name

-- Area Kanan (Pratinjau + Daftar Skin)
local rightPanel = Instance.new("Frame", mainFrame)
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(1, -225, 1, -60)
rightPanel.Position = UDim2.new(0, 215, 0, 50)
rightPanel.BackgroundTransparency = 1

-- Placeholder untuk ViewportFrame
-- ViewportFrame untuk Pratinjau
local viewportFrame = Instance.new("ViewportFrame", rightPanel)
viewportFrame.Name = "ViewportFrame"
viewportFrame.Size = UDim2.new(1, 0, 1, -130) -- Mengisi bagian atas rightPanel
viewportFrame.Position = UDim2.new(0, 0, 0, 0)
viewportFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
viewportFrame.BorderSizePixel = 0
viewportFrame.AmbientColor3 = Color3.new(0.5, 0.5, 0.5) -- Pencahayaan dasar
viewportFrame.LightColor = Color3.new(1, 1, 1)
viewportFrame.LightDirection = Vector3.new(-1, -1, -1)
local viewportCorner = Instance.new("UICorner", viewportFrame)
viewportCorner.CornerRadius = UDim.new(0, 8)

-- Slider untuk Zoom
-- Slider untuk Zoom (Vertikal)
-- Slider untuk Zoom (Horizontal, di dalam Viewport)
-- Komponen Slider Kustom
local sliderTrack = Instance.new("Frame", viewportFrame)
sliderTrack.Name = "SliderTrack"
sliderTrack.Size = UDim2.new(0.8, 0, 0, 10)
sliderTrack.Position = UDim2.new(0.1, 0, 1, -25)
sliderTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
sliderTrack.BorderSizePixel = 0
local trackCorner = Instance.new("UICorner", sliderTrack)
trackCorner.CornerRadius = UDim.new(0, 5)
sliderTrack.Visible = false

local sliderFill = Instance.new("Frame", sliderTrack)
sliderFill.Name = "SliderFill"
sliderFill.Size = UDim2.new(0.5, 0, 1, 0) -- Mulai di 50%
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
sliderFill.BorderSizePixel = 0
local fillCorner = Instance.new("UICorner", sliderFill)
fillCorner.CornerRadius = UDim.new(0, 5)

local sliderHandle = Instance.new("ImageButton", sliderTrack)
sliderHandle.Name = "SliderHandle"
sliderHandle.Size = UDim2.new(0, 20, 0, 20)
sliderHandle.AnchorPoint = Vector2.new(0.5, 0.5)
sliderHandle.Position = UDim2.new(0.5, 0, 0.5, 0)
sliderHandle.BackgroundColor3 = Color3.new(1, 1, 1)
sliderHandle.BorderSizePixel = 0
local handleCorner = Instance.new("UICorner", sliderHandle)
handleCorner.CornerRadius = UDim.new(1, 0) -- Lingkaran

-- WorldModel untuk mengelola lingkungan 3D di dalam ViewportFrame
local worldModel = Instance.new("WorldModel", viewportFrame)

-- Kamera untuk ViewportFrame
local viewportCamera = Instance.new("Camera")
viewportCamera.Parent = viewportFrame
viewportCamera.FieldOfView = 30
viewportFrame.CurrentCamera = viewportCamera

-- Skin List (Bawah Kanan) - Diubah menjadi list horizontal
local skinListFrame = Instance.new("ScrollingFrame", rightPanel)
skinListFrame.Name = "SkinListFrame"
skinListFrame.Size = UDim2.new(1, 0, 0, 120) -- Tinggi tetap
skinListFrame.Position = UDim2.new(0, 0, 1, -120) -- Di bagian bawah rightPanel
skinListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
skinListFrame.BackgroundTransparency = 0.5
skinListFrame.BorderSizePixel = 0
skinListFrame.CanvasSize = UDim2.new(2, 0, 0, 0) -- Aktifkan scrolling horizontal
local sl_layout = Instance.new("UIListLayout", skinListFrame)
sl_layout.Padding = UDim.new(0, 10)
sl_layout.FillDirection = Enum.FillDirection.Horizontal
sl_layout.VerticalAlignment = Enum.VerticalAlignment.Center

-- Equip Button
local equipButton = Instance.new("TextButton", mainFrame)
equipButton.Size = UDim2.new(1, -225, 0, 40)
equipButton.Position = UDim2.new(0, 215, 1, -50)
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
local currentPreviewModel = nil
local rotationConnection = nil
local currentZoomDistance = 5 -- Jarak zoom default

-- Fungsi untuk menghentikan rotasi model
local function stopRotation()
	if rotationConnection then
		rotationConnection:Disconnect()
		rotationConnection = nil
	end
end

-- Fungsi untuk memulai rotasi model
-- Fungsi untuk memulai rotasi model (dengan memutar kamera)
local function startRotation()
	stopRotation() -- Pastikan tidak ada koneksi ganda
	local cameraAngle = 0
	rotationConnection = RunService.RenderStepped:Connect(function(dt)
		if currentPreviewModel and currentPreviewModel.PrimaryPart then
			cameraAngle = cameraAngle + (dt * 0.8) -- Kecepatan rotasi

			local rotation = CFrame.Angles(0, cameraAngle, 0)
			local offset = Vector3.new(0, 0, currentZoomDistance)
			local cameraPosition = currentPreviewModel.PrimaryPart.Position + rotation:VectorToWorldSpace(offset)

			viewportCamera.CFrame = CFrame.new(cameraPosition, currentPreviewModel.PrimaryPart.Position)
		end
	end)
end

-- Fungsi untuk menampilkan model senjata di ViewportFrame
local function updatePreview(weaponName, skinName)
	-- Hapus model lama jika ada
	if currentPreviewModel then
		currentPreviewModel:Destroy()
		currentPreviewModel = nil
	end

	-- Jika tidak ada senjata/skin, sembunyikan slider dan keluar
	if not weaponName or not skinName then
		sliderTrack.Visible = false
		return
	end

	local weaponConfig = WeaponModule.Weapons[weaponName]
	if not weaponConfig or not weaponConfig.Skins[skinName] then return end

	local skinData = weaponConfig.Skins[skinName]

	-- Buat model baru untuk pratinjau
	local previewModel = Instance.new("Model")
	previewModel.Name = "WeaponPreviewModel"
	previewModel.Parent = worldModel

	local modelPart = Instance.new("Part")
	modelPart.Name = "Handle" -- Nama umum untuk primary part
	modelPart.Anchored = true
	modelPart.CanCollide = false
	modelPart.Size = Vector3.new(1, 1, 1)
	modelPart.CFrame = CFrame.new(0, 0, 0)
	modelPart.Parent = previewModel

	previewModel.PrimaryPart = modelPart

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = skinData.MeshId
	mesh.TextureId = skinData.TextureId
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = modelPart

	currentPreviewModel = previewModel

	-- Atur zoom default ke yang terdekat (paling besar)
	local minValue, maxValue = 2, 10
	currentZoomDistance = minValue -- Mulai dari jarak terdekat

	sliderTrack.Visible = true
	-- Atur posisi visual slider ke awal (0%) untuk mencerminkan zoom terdekat
	sliderHandle.Position = UDim2.new(0, 0, 0.5, 0)
	sliderFill.Size = UDim2.new(0, 0, 1, 0)
end

local function updateSkinList()
	for _, child in ipairs(skinListFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then -- Diubah dari UIGridLayout
			child:Destroy()
		end
	end
	selectedSkin = nil
	equipButton.AutoButtonColor = false
	equipButton.BackgroundColor3 = Color3.fromRGB(130, 130, 130)

	if not selectedWeapon or not inventoryData then return end

	local ownedSkins = inventoryData.Skins.Owned[selectedWeapon]
	local equippedSkin = inventoryData.Skins.Equipped[selectedWeapon]

	-- Urutkan skin agar yang di-equip muncul pertama
	table.sort(ownedSkins, function(a, b)
		if a == equippedSkin then return true end
		if b == equippedSkin then return false end
		return a < b
	end)

	for _, skinName in ipairs(ownedSkins) do
		local skinButton = Instance.new("ImageButton") -- Diubah ke ImageButton untuk pratinjau mini
		skinButton.Name = skinName
		skinButton.Size = UDim2.new(0, 100, 0, 100) -- Ukuran persegi
		skinButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
		skinButton.Parent = skinListFrame
		local skinCorner = Instance.new("UICorner", skinButton)
		skinCorner.CornerRadius = UDim.new(0, 6)

		local skinLabel = Instance.new("TextLabel", skinButton)
		skinLabel.Size = UDim2.new(1, 0, 0, 20)
		skinLabel.Position = UDim2.new(0, 0, 1, -20)
		skinLabel.Text = skinName
		skinLabel.Font = Enum.Font.SourceSans
		skinLabel.TextSize = 14
		skinLabel.TextColor3 = Color3.new(1, 1, 1)
		skinLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		skinLabel.BackgroundTransparency = 0.3

		if skinName == equippedSkin then
			skinButton.BackgroundColor3 = Color3.fromRGB(0, 170, 81)
		end

		skinButton.MouseButton1Click:Connect(function()
			selectedSkin = skinName
			-- Update preview
			updatePreview(selectedWeapon, selectedSkin)

			for _, btn in ipairs(skinListFrame:GetChildren()) do
				if btn:IsA("ImageButton") then
					if inventoryData.Skins.Equipped[selectedWeapon] == btn.Name then
						btn.BackgroundColor3 = Color3.fromRGB(0, 170, 81)
					else
						btn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
					end
				end
			end
			skinButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Warna oranye untuk yang dipilih

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

			-- Tampilkan pratinjau skin yang sedang digunakan saat senjata dipilih
			local equippedSkin = inventoryData.Skins.Equipped[selectedWeapon]
			updatePreview(selectedWeapon, equippedSkin)
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
	startRotation() -- Mulai rotasi saat menu dibuka
end)

-- Tombol untuk kembali dari menu inventaris
backButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	inventoryButton.Visible = true
	-- Hapus model dari pratinjau saat menu ditutup
	updatePreview(nil, nil)
	stopRotation() -- Hentikan rotasi saat menu ditutup
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

-- Hubungkan logika zoom ke slider
-- Logika Slider Kustom
local isDragging = false
local minValue, maxValue = 2, 10

sliderHandle.MouseButton1Down:Connect(function()
	isDragging = true
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local mouseX = input.Position.X
		local trackAbsX = sliderTrack.AbsolutePosition.X
		local trackAbsWidth = sliderTrack.AbsoluteSize.X

		-- Batasi posisi mouse agar berada di dalam batas trek
		local clampedMouseX = math.clamp(mouseX, trackAbsX, trackAbsX + trackAbsWidth)

		-- Hitung posisi baru sebagai persentase
		local percent = (clampedMouseX - trackAbsX) / trackAbsWidth

		-- Perbarui pegangan dan isian
		sliderHandle.Position = UDim2.new(percent, 0, 0.5, 0)
		sliderFill.Size = UDim2.new(percent, 0, 1, 0)

		-- Perbarui nilai zoom yang sebenarnya
		currentZoomDistance = minValue + (percent * (maxValue - minValue))
	end
end)