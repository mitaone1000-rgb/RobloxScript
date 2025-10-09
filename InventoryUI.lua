-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Script Place: Lobby

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
inventoryButton.AnchorPoint = Vector2.new(0.5, 1) -- Jangkar di tengah bawah
inventoryButton.Size = UDim2.new(0.2, 0, 0.1, 0) -- 20% lebar, 10% tinggi
inventoryButton.Position = UDim2.new(0.5, 0, 0.98, 0) -- Posisi di tengah bawah dengan sedikit padding
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
-- Menggunakan Scale agar responsif, AnchorPoint di tengah
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0) -- 80% lebar, 80% tinggi
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Tepat di tengah layar
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35) -- Warna arang gelap
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Active = true
mainFrame.Visible = false -- Awalnya disembunyikan

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = mainFrame

-- Menjaga aspek rasio agar frame tidak gepeng/terlalu lebar
local aspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
aspectRatioConstraint.AspectRatio = 1.6 -- Rasio dari ukuran asli (800/500)
aspectRatioConstraint.DominantAxis = Enum.DominantAxis.Width -- Ukuran disesuaikan berdasarkan lebar
aspectRatioConstraint.Parent = mainFrame

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0.1, 0) -- 10% tinggi dari parent (mainFrame)
title.Text = "INVENTORY"
title.Font = Enum.Font.Creepster -- Font tema horor
title.TextSize = 36
title.TextColor3 = Color3.fromRGB(180, 20, 20) -- Merah darah gelap
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
local titleCorner = Instance.new("UICorner", title)
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local backButton = Instance.new("TextButton", mainFrame)
backButton.Size = UDim2.new(0.1, 0, 0.08, 0) -- 10% lebar, 8% tinggi
backButton.Position = UDim2.new(0.02, 0, 0.01, 0) -- Sedikit padding dari atas kiri
backButton.Text = "Back"
backButton.Font = Enum.Font.SourceSans
backButton.TextSize = 16
backButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
backButton.TextColor3 = Color3.new(1, 1, 1)
local backCorner = Instance.new("UICorner", backButton)
backCorner.CornerRadius = UDim.new(0, 6)

-- Layout Frame untuk menampung weaponList dan rightPanel
local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(0.95, 0, 0.88, 0) -- Mengisi sisa area di bawah title
contentFrame.Position = UDim2.new(0.5, 0, 0.54, 0) -- Diposisikan di bawah title
contentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
contentFrame.BackgroundTransparency = 1

-- Weapon List (Left Side)
local weaponListFrame = Instance.new("ScrollingFrame", contentFrame)
weaponListFrame.Name = "WeaponListFrame"
weaponListFrame.Size = UDim2.new(0.25, 0, 1, 0) -- 25% dari lebar contentFrame
weaponListFrame.Position = UDim2.new(0, 0, 0, 0)
weaponListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
local wl_layout = Instance.new("UIListLayout", weaponListFrame)
wl_layout.Padding = UDim.new(0, 5)
wl_layout.SortOrder = Enum.SortOrder.Name

-- Area Kanan (Pratinjau + Daftar Skin)
local rightPanel = Instance.new("Frame", contentFrame)
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(0.74, 0, 1, 0) -- 74% dari lebar contentFrame (menyisakan 1% gap)
rightPanel.Position = UDim2.new(0.26, 0, 0, 0) -- Diposisikan di sebelah kanan weaponList
rightPanel.BackgroundTransparency = 1

-- Placeholder untuk ViewportFrame
-- ViewportFrame untuk Pratinjau
local viewportFrame = Instance.new("ViewportFrame", rightPanel)
viewportFrame.Name = "ViewportFrame"
viewportFrame.Size = UDim2.new(1, 0, 0.5, 0) -- 50% tinggi dari rightPanel
viewportFrame.Position = UDim2.new(0, 0, 0, 0)
viewportFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
viewportFrame.BorderSizePixel = 0
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

-- NEW: Frame untuk Statistik Senjata
local statsFrame = Instance.new("Frame", rightPanel)
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(1, 0, 0.2, 0) -- 20% tinggi, beri ruang untuk skin list
statsFrame.Position = UDim2.new(0, 0, 0.5, 5) -- Di bawah viewport, dengan 5px gap
statsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
statsFrame.BorderSizePixel = 0
statsFrame.Visible = false -- Sembunyikan awalnya
local statsCorner = Instance.new("UICorner", statsFrame)
statsCorner.CornerRadius = UDim.new(0, 8)

-- Layout untuk statistik
local statsLayout = Instance.new("UIPadding", statsFrame)
statsLayout.PaddingLeft = UDim.new(0, 10)
statsLayout.PaddingRight = UDim.new(0, 10)
statsLayout.PaddingTop = UDim.new(0, 5)
statsLayout.PaddingBottom = UDim.new(0, 5)

local statsListLayout = Instance.new("UIListLayout", statsFrame)
statsListLayout.Padding = UDim.new(0, 8)

-- Judul Statistik
local statsTitle = Instance.new("TextLabel", statsFrame)
statsTitle.Name = "StatsTitle"
statsTitle.Size = UDim2.new(1, 0, 0, 20)
statsTitle.Text = "STATISTICS"
statsTitle.Font = Enum.Font.SourceSansBold
statsTitle.TextSize = 18
statsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
statsTitle.BackgroundTransparency = 1

-- Frame untuk baris Damage
local damageFrame = Instance.new("Frame", statsFrame)
damageFrame.BackgroundTransparency = 1
damageFrame.Size = UDim2.new(1, 0, 0, 20)
local damageLayout = Instance.new("UIListLayout", damageFrame)
damageLayout.FillDirection = Enum.FillDirection.Horizontal
damageLayout.VerticalAlignment = Enum.VerticalAlignment.Center
damageLayout.Padding = UDim.new(0, 5)

local damageIcon = Instance.new("ImageLabel", damageFrame)
damageIcon.Size = UDim2.new(0, 20, 0, 20)
damageIcon.BackgroundTransparency = 1
damageIcon.Image = "rbxassetid://13858487184" -- Placeholder ID Ikon Target
damageIcon.ImageColor3 = Color3.fromRGB(220, 220, 220)

local damageLabel = Instance.new("TextLabel", damageFrame)
damageLabel.Font = Enum.Font.SourceSans
damageLabel.TextSize = 16
damageLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
damageLabel.BackgroundTransparency = 1
damageLabel.TextXAlignment = Enum.TextXAlignment.Left
damageLabel.Size = UDim2.new(1, -25, 1, 0)
damageLabel.Text = "Damage: -"

-- Frame untuk baris Amunisi
local ammoFrame = Instance.new("Frame", statsFrame)
ammoFrame.BackgroundTransparency = 1
ammoFrame.Size = UDim2.new(1, 0, 0, 20)
local ammoLayout = Instance.new("UIListLayout", ammoFrame)
ammoLayout.FillDirection = Enum.FillDirection.Horizontal
ammoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ammoLayout.Padding = UDim.new(0, 5)

local ammoIcon = Instance.new("ImageLabel", ammoFrame)
ammoIcon.Size = UDim2.new(0, 20, 0, 20)
ammoIcon.BackgroundTransparency = 1
ammoIcon.Image = "rbxassetid://13858484964" -- Placeholder ID Ikon Peluru
ammoIcon.ImageColor3 = Color3.fromRGB(220, 220, 220)

local ammoLabel = Instance.new("TextLabel", ammoFrame)
ammoLabel.Font = Enum.Font.SourceSans
ammoLabel.TextSize = 16
ammoLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
ammoLabel.BackgroundTransparency = 1
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.Size = UDim2.new(1, -25, 1, 0)
ammoLabel.Text = "Ammunition: -"

-- Frame untuk baris Recoil
local recoilFrame = Instance.new("Frame", statsFrame)
recoilFrame.BackgroundTransparency = 1
recoilFrame.Size = UDim2.new(1, 0, 0, 20)
local recoilLayout = Instance.new("UIListLayout", recoilFrame)
recoilLayout.FillDirection = Enum.FillDirection.Horizontal
recoilLayout.VerticalAlignment = Enum.VerticalAlignment.Center
recoilLayout.Padding = UDim.new(0, 5)

local recoilLabel = Instance.new("TextLabel", recoilFrame)
recoilLabel.Font = Enum.Font.SourceSans
recoilLabel.TextSize = 16
recoilLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
recoilLabel.BackgroundTransparency = 1
recoilLabel.TextXAlignment = Enum.TextXAlignment.Left
recoilLabel.Size = UDim2.new(0, 55, 1, 0)
recoilLabel.Text = "Recoil:"

local recoilBarTrack = Instance.new("Frame", recoilFrame)
recoilBarTrack.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
recoilBarTrack.Size = UDim2.new(1, -60, 0, 12)
recoilBarTrack.LayoutOrder = 2
local recoilTrackCorner = Instance.new("UICorner", recoilBarTrack)
recoilTrackCorner.CornerRadius = UDim.new(0, 6)

local recoilBarFill = Instance.new("Frame", recoilBarTrack)
recoilBarFill.BackgroundColor3 = Color3.fromRGB(80, 180, 80) -- Hijau untuk rekoil rendah
recoilBarFill.Size = UDim2.new(0.2, 0, 1, 0) -- Mulai dengan nilai rendah
local recoilFillCorner = Instance.new("UICorner", recoilBarFill)
recoilFillCorner.CornerRadius = UDim.new(0, 6)

-- Garis Pemisah
local separator = Instance.new("Frame", rightPanel)
separator.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
separator.BorderSizePixel = 0
separator.Size = UDim2.new(1, 0, 0, 2)
separator.Position = UDim2.new(0, 0, 0.7, 4)

-- Skin List (Bawah Kanan) - Diubah menjadi list horizontal
local skinListFrame = Instance.new("ScrollingFrame", rightPanel)
skinListFrame.Name = "SkinListFrame"
skinListFrame.Size = UDim2.new(1, 0, 0.3, 0) -- 30% tinggi dari rightPanel
skinListFrame.Position = UDim2.new(0, 0, 0.7, 10) -- Diposisikan di bawah statsFrame
skinListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
skinListFrame.BackgroundTransparency = 0.5
skinListFrame.BorderSizePixel = 0
skinListFrame.CanvasSize = UDim2.new(2, 0, 0, 0) -- Aktifkan scrolling horizontal
local sl_layout = Instance.new("UIListLayout", skinListFrame)
sl_layout.Padding = UDim.new(0, 10)
sl_layout.FillDirection = Enum.FillDirection.Horizontal
sl_layout.VerticalAlignment = Enum.VerticalAlignment.Center

-- Equip Button
local equipButton = Instance.new("TextButton", rightPanel) -- Parent diubah ke rightPanel
equipButton.Name = "EquipButton"
equipButton.AnchorPoint = Vector2.new(0.5, 0) -- Jangkar di tengah atas
equipButton.Size = UDim2.new(1, 0, 0.1, 0) -- Lebar 100% dari rightPanel, tinggi 10% dari rightPanel
equipButton.Position = UDim2.new(0.5, 0, 1.02, 0) -- Diposisikan sedikit di bawah rightPanel
equipButton.Text = "Equip Skin"
equipButton.Font = Enum.Font.SourceSansBold
equipButton.TextSize = 18
equipButton.BackgroundColor3 = Color3.fromRGB(130, 130, 130) -- Disabled
equipButton.TextColor3 = Color3.new(1, 1, 1)
local equipCorner = Instance.new("UICorner", equipButton)
equipCorner.CornerRadius = UDim.new(0, 8)
equipButton.AutoButtonColor = false

-- Layout Adaptif
local mobileLayout = Instance.new("UIListLayout")
mobileLayout.Name = "MobileLayout"
mobileLayout.FillDirection = Enum.FillDirection.Vertical
mobileLayout.SortOrder = Enum.SortOrder.LayoutOrder
mobileLayout.Padding = UDim.new(0, 10)
-- Parent diatur ke nil pada awalnya untuk menonaktifkannya

local function updateLayout()
	local screenSize = inventoryScreenGui.AbsoluteSize
	local isMobile = screenSize.X < 720 -- Ambang batas untuk layout mobile

	if isMobile then
		-- Layout Vertikal untuk Mobile
		mobileLayout.Parent = contentFrame -- Aktifkan layout dengan mengatur Parent
		weaponListFrame.Size = UDim2.new(1, 0, 0.4, 0)
		rightPanel.Size = UDim2.new(1, 0, 0.58, 0)
		rightPanel.Position = UDim2.new(0, 0, 0, 0) -- Dikelola oleh ListLayout
	else
		-- Layout Horizontal untuk Desktop
		mobileLayout.Parent = nil -- Nonaktifkan layout dengan menghapus Parent
		weaponListFrame.Size = UDim2.new(0.25, 0, 1, 0)
		rightPanel.Size = UDim2.new(0.74, 0, 1, 0)
		rightPanel.Position = UDim2.new(0.26, 0, 0, 0)
	end
end

-- Panggil fungsi penyesuaian layout setiap kali ukuran layar berubah
inventoryScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)

-- Panggil sekali di awal untuk mengatur layout awal
task.wait() -- Tunggu sejenak agar ukuran awal UI dihitung dengan benar
updateLayout()

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

-- Fungsi untuk memperbarui tampilan statistik
local function updateStatsDisplay(weaponName)
	if not weaponName or not WeaponModule.Weapons[weaponName] then
		statsFrame.Visible = false
		return
	end

	statsFrame.Visible = true
	local data = WeaponModule.Weapons[weaponName]

	-- Update Damage & Amunisi
	damageLabel.Text = "Damage: " .. tostring(data.Damage)
	ammoLabel.Text = "Ammunition: " .. tostring(data.MaxAmmo) .. " / " .. tostring(data.ReserveAmmo)

	-- Update Bilah Recoil
	local maxRecoil = 10 -- Nilai referensi untuk recoil maksimum
	local recoilPercentage = math.clamp(data.Recoil / maxRecoil, 0, 1)

	-- Ubah ukuran bilah
	recoilBarFill.Size = UDim2.new(recoilPercentage, 0, 1, 0)

	-- Ubah warna bilah berdasarkan persentase
	local lowColor = Color3.fromRGB(80, 180, 80) -- Hijau
	local midColor = Color3.fromRGB(220, 200, 70) -- Kuning
	local highColor = Color3.fromRGB(180, 20, 20) -- Merah

	if recoilPercentage < 0.5 then
		-- Transisi dari Hijau ke Kuning
		recoilBarFill.BackgroundColor3 = lowColor:Lerp(midColor, recoilPercentage * 2)
	else
		-- Transisi dari Kuning ke Merah
		recoilBarFill.BackgroundColor3 = midColor:Lerp(highColor, (recoilPercentage - 0.5) * 2)
	end
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

		-- Menjaga agar tombol skin tetap persegi
		local skinAspect = Instance.new("UIAspectRatioConstraint")
		skinAspect.AspectRatio = 1.0
		skinAspect.Parent = skinButton

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
			skinButton.BackgroundColor3 = Color3.fromRGB(180, 20, 20) -- Warna merah darah untuk yang dipilih

			if selectedSkin ~= equippedSkin then
				equipButton.AutoButtonColor = true
				equipButton.BackgroundColor3 = Color3.fromRGB(180, 20, 20) -- Merah darah
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
			weaponButton.BackgroundColor3 = Color3.fromRGB(80, 25, 25) -- Warna sorotan merah gelap
			updateSkinList()
			updateStatsDisplay(weaponName) -- Tampilkan statistik

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
	updateStatsDisplay(nil) -- Sembunyikan statistik
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
