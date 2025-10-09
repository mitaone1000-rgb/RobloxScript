-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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
-- Layout Frame untuk menampung kolom
local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(0.95, 0, 0.88, 0)
contentFrame.Position = UDim2.new(0.5, 0, 0.54, 0)
contentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
contentFrame.BackgroundTransparency = 1
local contentLayout = Instance.new("UIListLayout", contentFrame)
contentLayout.FillDirection = Enum.FillDirection.Horizontal
contentLayout.Padding = UDim.new(0, 0) -- Padding diatur ke 0
contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center

-- Kolom Kiri: Daftar Senjata (25%)
local leftColumn = Instance.new("Frame", contentFrame)
leftColumn.Name = "LeftColumn"
leftColumn.Size = UDim2.new(0.25, 0, 1, 0) -- Lebar disesuaikan
leftColumn.BackgroundTransparency = 1
leftColumn.LayoutOrder = 1
-- Menggunakan UIListLayout untuk mengatur frame filter dan daftar senjata
local leftColumnLayout = Instance.new("UIListLayout", leftColumn)
leftColumnLayout.FillDirection = Enum.FillDirection.Vertical
leftColumnLayout.Padding = UDim.new(0, 10)

-- Frame untuk tombol filter kategori
local categoryFilterFrame = Instance.new("Frame", leftColumn)
categoryFilterFrame.Name = "CategoryFilterFrame"
categoryFilterFrame.Size = UDim2.new(1, 0, 0, 70) -- Tinggi ditambah untuk 2 baris
categoryFilterFrame.BackgroundTransparency = 1
local cf_layout = Instance.new("UIGridLayout", categoryFilterFrame)
cf_layout.CellPadding = UDim2.new(0, 5, 0, 5)
cf_layout.CellSize = UDim2.new(0.45, 0, 0.45, 0)
cf_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cf_layout.VerticalAlignment = Enum.VerticalAlignment.Center

local weaponListFrame = Instance.new("ScrollingFrame", leftColumn)
weaponListFrame.Name = "WeaponListFrame"
weaponListFrame.Size = UDim2.new(1, 0, 1, -80) -- Ukuran disesuaikan untuk memberi ruang pada filter
weaponListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
local wl_corner = Instance.new("UICorner", weaponListFrame)
wl_corner.CornerRadius = UDim.new(0, 8)
local wl_layout = Instance.new("UIListLayout", weaponListFrame)
wl_layout.Padding = UDim.new(0, 5)
wl_layout.SortOrder = Enum.SortOrder.Name
local wl_padding = Instance.new("UIPadding", weaponListFrame)
wl_padding.PaddingLeft = UDim.new(0, 10)
wl_padding.PaddingRight = UDim.new(0, 10)
wl_padding.PaddingTop = UDim.new(0, 5)
wl_padding.PaddingBottom = UDim.new(0, 5)

-- Pemisah 1
local separator1 = Instance.new("Frame", contentFrame)
separator1.Name = "Separator1"
separator1.Size = UDim2.new(0.005, 0, 1, 0) -- Lebar 0.5%
separator1.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
separator1.BorderSizePixel = 0
separator1.LayoutOrder = 2

-- Kolom Tengah: Pratinjau 3D (44%)
local middleColumn = Instance.new("Frame", contentFrame)
middleColumn.Name = "MiddleColumn"
middleColumn.Size = UDim2.new(0.44, 0, 1, 0) -- Lebar disesuaikan
middleColumn.BackgroundTransparency = 1
middleColumn.LayoutOrder = 3

-- Pemisah 2
local separator2 = Instance.new("Frame", contentFrame)
separator2.Name = "Separator2"
separator2.Size = UDim2.new(0.005, 0, 1, 0) -- Lebar 0.5%
separator2.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
separator2.BorderSizePixel = 0
separator2.LayoutOrder = 4

-- Kolom Kanan: Info & Aksi (30%)
local rightColumn = Instance.new("Frame", contentFrame)
rightColumn.Name = "RightColumn"
rightColumn.Size = UDim2.new(0.3, 0, 1, 0)
rightColumn.BackgroundTransparency = 1
rightColumn.LayoutOrder = 5
local rightColumnLayout = Instance.new("UIListLayout", rightColumn)
rightColumnLayout.Padding = UDim.new(0, 10)
rightColumnLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- [BARU] Judul Senjata di Kolom Kanan
local weaponTitleLabel = Instance.new("TextLabel", rightColumn)
weaponTitleLabel.Name = "WeaponTitleLabel"
weaponTitleLabel.Size = UDim2.new(1, 0, 0, 40)
weaponTitleLabel.Font = Enum.Font.Creepster
weaponTitleLabel.Text = "SELECT A WEAPON"
weaponTitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
weaponTitleLabel.TextSize = 32
weaponTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponTitleLabel.BackgroundTransparency = 1
weaponTitleLabel.LayoutOrder = 1
weaponTitleLabel.Visible = true

-- [BARU] Frame untuk Statistik Visual
local statsFrame = Instance.new("Frame", rightColumn)
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(1, 0, 0, 100) -- Ukuran disesuaikan untuk bilah progres
statsFrame.BackgroundTransparency = 1
statsFrame.LayoutOrder = 2
local statsLayout = Instance.new("UIListLayout", statsFrame)
statsLayout.Padding = UDim.new(0, 8)

-- Fungsi helper untuk membuat bilah statistik
local function createStatBar(name, parent)
	local statFrame = Instance.new("Frame", parent)
	statFrame.Name = name .. "Stat"
	statFrame.Size = UDim2.new(1, 0, 0, 24)
	statFrame.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout", statFrame)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 2)

	local title = Instance.new("TextLabel", statFrame)
	title.Size = UDim2.new(1, 0, 0, 12)
	title.Text = string.upper(name)
	title.Font = Enum.Font.SourceSansBold
	title.TextColor3 = Color3.fromRGB(180, 180, 180)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1

	local barTrack = Instance.new("Frame", statFrame)
	barTrack.Size = UDim2.new(1, 0, 0, 8)
	barTrack.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	local trackCorner = Instance.new("UICorner", barTrack)
	trackCorner.CornerRadius = UDim.new(1, 0)

	local barFill = Instance.new("Frame", barTrack)
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	local fillCorner = Instance.new("UICorner", barFill)
	fillCorner.CornerRadius = UDim.new(1, 0)

	return barFill
end

local damageBar = createStatBar("Damage", statsFrame)
local ammoBar = createStatBar("Ammo", statsFrame)
local recoilBar = createStatBar("Recoil", statsFrame)

-- [BARU] Judul untuk daftar skin
local skinsTitle = Instance.new("TextLabel", rightColumn)
skinsTitle.Name = "SkinsTitle"
skinsTitle.Size = UDim2.new(1, 0, 0, 20)
skinsTitle.Text = "AVAILABLE SKINS"
skinsTitle.Font = Enum.Font.SourceSansBold
skinsTitle.TextSize = 16
skinsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
skinsTitle.BackgroundTransparency = 1
skinsTitle.LayoutOrder = 3

-- [BARU] ScrollingFrame Horizontal untuk Skins
local skinListFrame = Instance.new("ScrollingFrame", rightColumn)
skinListFrame.Name = "SkinListFrame"
skinListFrame.Size = UDim2.new(1, 0, 0, 100) -- Ukuran untuk thumbnail
skinListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
skinListFrame.BackgroundTransparency = 0.5
skinListFrame.BorderSizePixel = 0
skinListFrame.LayoutOrder = 4
skinListFrame.CanvasSize = UDim2.new(2, 0, 0, 0) -- Aktifkan scrolling horizontal
skinListFrame.ScrollBarThickness = 4
skinListFrame.ScrollingDirection = Enum.ScrollingDirection.X

local sl_layout = Instance.new("UIListLayout", skinListFrame)
sl_layout.FillDirection = Enum.FillDirection.Horizontal
sl_layout.Padding = UDim.new(0, 10)
sl_layout.VerticalAlignment = Enum.VerticalAlignment.Center

-- [BARU] Tombol Equip yang Didesain Ulang
local equipButton = Instance.new("TextButton", rightColumn)
equipButton.Name = "EquipButton"
equipButton.Size = UDim2.new(1, 0, 0, 40)
equipButton.Text = "EQUIP SKIN"
equipButton.Font = Enum.Font.SourceSansBold
equipButton.TextSize = 18
equipButton.BackgroundColor3 = Color3.fromRGB(130, 130, 130) -- Warna non-aktif
equipButton.TextColor3 = Color3.new(1, 1, 1)
equipButton.LayoutOrder = 5
local equipCorner = Instance.new("UICorner", equipButton)
equipCorner.CornerRadius = UDim.new(0, 8)
equipButton.AutoButtonColor = false

-- ViewportFrame untuk Pratinjau
local viewportFrame = Instance.new("ViewportFrame", middleColumn)
viewportFrame.Name = "ViewportFrame"
viewportFrame.Size = UDim2.new(1, 0, 1, 0) -- Mengisi seluruh kolom tengah
viewportFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
viewportFrame.BorderSizePixel = 0
viewportFrame.LightColor = Color3.new(1, 1, 1)
viewportFrame.LightDirection = Vector3.new(-1, -1, -1)
local viewportCorner = Instance.new("UICorner", viewportFrame)
viewportCorner.CornerRadius = UDim.new(0, 8)

-- Slider untuk Zoom
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
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
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
handleCorner.CornerRadius = UDim.new(1, 0)

-- WorldModel & Kamera
local worldModel = Instance.new("WorldModel", viewportFrame)
local viewportCamera = Instance.new("Camera")
viewportCamera.Parent = viewportFrame
viewportCamera.FieldOfView = 30
viewportFrame.CurrentCamera = viewportCamera

-- Frame untuk Statistik Senjata

-- Hapus fungsi updateLayout yang lama karena tidak lagi digunakan
-- Panggil sekali di awal untuk mengatur layout awal
task.wait() -- Tunggu sejenak agar ukuran awal UI dihitung dengan benar

-- State variables
local inventoryData = nil
local selectedWeapon = nil
local selectedSkin = nil
local currentPreviewModel = nil
local rotationConnection = nil
local currentZoomDistance = 5 -- Jarak zoom default
local selectedCategory = "All" -- Kategori default
local categoryButtons = {}

-- Forward declare functions to avoid nil errors on callbacks
local updateWeaponList

function updateWeaponList(categoryFilter)
	for _, child in ipairs(weaponListFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local weaponNames = {}
	for name, data in pairs(WeaponModule.Weapons) do
		if categoryFilter == "All" or (data.Category and data.Category == categoryFilter) then
			table.insert(weaponNames, name)
		end
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

			updateStatsDisplay(weaponName)
			updateSkinList()

			local equippedSkin = inventoryData.Skins.Equipped[selectedWeapon]
			updatePreview(selectedWeapon, equippedSkin)
		end)
	end
end


-- [BARU] Fungsi untuk membuat dan mengelola tombol kategori
local function createCategoryButtons()
	local categories = {"All", "Pistol", "Assault Rifle", "SMG", "Shotgun", "Sniper", "LMG"}

	-- Fungsi untuk menyorot tombol aktif
	local function highlightActiveButton()
		for name, button in pairs(categoryButtons) do
			if name == selectedCategory then
				button.BackgroundColor3 = Color3.fromRGB(180, 20, 20) -- Warna aktif
				button.TextColor3 = Color3.new(1, 1, 1)
			else
				button.BackgroundColor3 = Color3.fromRGB(85, 85, 85) -- Warna non-aktif
				button.TextColor3 = Color3.new(0.8, 0.8, 0.8)
			end
		end
	end

	-- Hanya buat tombol jika belum ada
	if #categoryFilterFrame:GetChildren() > 1 then
		highlightActiveButton()
		return
	end

	for _, categoryName in ipairs(categories) do
		local categoryButton = Instance.new("TextButton")
		categoryButton.Name = categoryName
		-- Ukuran tidak diatur secara eksplisit, biarkan UIGridLayout yang mengatur
		categoryButton.Text = categoryName
		categoryButton.Font = Enum.Font.SourceSans
		categoryButton.TextSize = 12 -- Ukuran font disesuaikan
		local btnCorner = Instance.new("UICorner", categoryButton)
		btnCorner.CornerRadius = UDim.new(0, 6)
		categoryButton.Parent = categoryFilterFrame

		categoryButtons[categoryName] = categoryButton

		categoryButton.MouseButton1Click:Connect(function()
			selectedCategory = categoryName
			highlightActiveButton()
			updateWeaponList(selectedCategory)
		end)
	end

	highlightActiveButton()
end

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
	local minValue, maxValue = 2.5, 10 -- Diubah dari 2 ke 4
	currentZoomDistance = minValue -- Mulai dari jarak terdekat

	sliderTrack.Visible = true
	-- Atur posisi visual slider ke awal (0%) untuk mencerminkan zoom terdekat
	sliderHandle.Position = UDim2.new(0, 0, 0.5, 0)
	sliderFill.Size = UDim2.new(0, 0, 1, 0)
end

-- Fungsi untuk memperbarui tampilan statistik
-- [BARU] Referensi untuk kalkulasi bar statistik
local MAX_DAMAGE = 150
local MAX_AMMO = 200
local MAX_RECOIL = 10

-- [DIUBAH] Fungsi untuk memperbarui tampilan statistik visual
local function updateStatsDisplay(weaponName)
	local data = weaponName and WeaponModule.Weapons[weaponName]

	if not data then
		statsFrame.Visible = false
		weaponTitleLabel.Text = "SELECT A WEAPON"
		return
	end

	statsFrame.Visible = true
	weaponTitleLabel.Text = string.upper(weaponName)

	local damagePercent = math.clamp(data.Damage / MAX_DAMAGE, 0, 1)
	local ammoPercent = math.clamp(data.MaxAmmo / MAX_AMMO, 0, 1)
	-- Recoil lebih baik jika nilainya rendah, jadi kita balik persentasenya untuk bar
	local recoilPercent = 1 - math.clamp(data.Recoil / MAX_RECOIL, 0, 1)

	-- Tweening untuk perubahan yang mulus
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	TweenService:Create(damageBar, tweenInfo, {Size = UDim2.new(damagePercent, 0, 1, 0)}):Play()
	TweenService:Create(ammoBar, tweenInfo, {Size = UDim2.new(ammoPercent, 0, 1, 0)}):Play()
	TweenService:Create(recoilBar, tweenInfo, {Size = UDim2.new(recoilPercent, 0, 1, 0)}):Play()

	-- Warna merepresentasikan "kebaikan" stat. Hijau bagus, merah jelek.
	local lowColor = Color3.fromRGB(180, 20, 20) -- Merah (jelek)
	local highColor = Color3.fromRGB(80, 180, 80) -- Hijau (bagus)

	damageBar.BackgroundColor3 = lowColor:Lerp(highColor, damagePercent)
	ammoBar.BackgroundColor3 = lowColor:Lerp(highColor, ammoPercent)
	recoilBar.BackgroundColor3 = lowColor:Lerp(highColor, recoilPercent)
end

-- [DIUBAH] Fungsi untuk memperbarui daftar skin horizontal
-- [DIUBAH & DIPERBAIKI] Fungsi untuk memperbarui daftar skin horizontal
local function updateSkinList()
	-- Bersihkan daftar skin sebelum mengisi ulang
	for _, child in ipairs(skinListFrame:GetChildren()) do
		if not child:IsA("UILayout") then
			child:Destroy()
		end
	end

	selectedSkin = nil

	-- Sembunyikan dan nonaktifkan elemen jika tidak ada senjata yang dipilih
	local weaponData = selectedWeapon and WeaponModule.Weapons[selectedWeapon]
	if not weaponData or not weaponData.Skins or not inventoryData then
		skinListFrame.Visible = false
		skinsTitle.Visible = false
		equipButton.Visible = false
		return
	end

	-- Tampilkan kembali elemen
	skinListFrame.Visible = true
	skinsTitle.Visible = true
	equipButton.Visible = true

	local ownedSkins = inventoryData.Skins.Owned[selectedWeapon]
	local equippedSkin = inventoryData.Skins.Equipped[selectedWeapon]

	-- Fungsi untuk mengatur status tombol Equip
	local function setEquipButtonState()
		if not selectedSkin then
			equipButton.Text = "SELECT A SKIN"
			equipButton.AutoButtonColor = false
			equipButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85) -- Warna diseragamkan
		elseif selectedSkin == equippedSkin then
			equipButton.Text = "EQUIPPED"
			equipButton.AutoButtonColor = false
			equipButton.BackgroundColor3 = Color3.fromRGB(0, 170, 81) -- Warna hijau untuk equipped
		else
			equipButton.Text = "EQUIP " .. string.upper(selectedSkin)
			equipButton.AutoButtonColor = true
			equipButton.BackgroundColor3 = Color3.fromRGB(180, 20, 20) -- Warna merah untuk equip
		end
	end

	-- Fungsi untuk mengatur ulang border semua thumbnail skin
	local function resetAllBorders()
		for _, btn in ipairs(skinListFrame:GetChildren()) do
			if btn:IsA("ImageButton") and btn:FindFirstChild("UIStroke") then
				local btnBorder = btn:FindFirstChild("UIStroke")
				if btn.Name == equippedSkin then
					btnBorder.Color = Color3.fromRGB(0, 200, 100) -- Hijau untuk yang terpasang
					btnBorder.Thickness = 3
				else
					btnBorder.Color = Color3.fromRGB(80, 80, 80) -- Abu-abu standar
					btnBorder.Thickness = 2
				end
			end
		end
	end

	-- Urutkan skin agar yang di-equip muncul pertama
	table.sort(ownedSkins, function(a, b)
		if a == equippedSkin then return true end
		if b == equippedSkin then return false end
		return a < b
	end)

	-- Buat thumbnail untuk setiap skin
	for i, skinName in ipairs(ownedSkins) do
		local skinData = WeaponModule.Weapons[selectedWeapon].Skins[skinName]
		if skinData then
			local thumbButton = Instance.new("ImageButton")
			thumbButton.Name = skinName
			thumbButton.Size = UDim2.new(0, 80, 0, 80)
			thumbButton.Image = skinData.TextureId or ""
			thumbButton.ScaleType = Enum.ScaleType.Fit
			thumbButton.LayoutOrder = i
			thumbButton.Parent = skinListFrame

			local corner = Instance.new("UICorner", thumbButton)
			corner.CornerRadius = UDim.new(0, 6)

			local border = Instance.new("UIStroke", thumbButton)
			border.Thickness = 2
			border.Color = Color3.fromRGB(80, 80, 80)

			thumbButton.MouseButton1Click:Connect(function()
				selectedSkin = skinName
				updatePreview(selectedWeapon, selectedSkin)
				resetAllBorders()

				-- Sorot thumbnail yang dipilih
				border.Color = Color3.fromRGB(220, 50, 50) -- Merah untuk pilihan
				border.Thickness = 3

				setEquipButtonState()
			end)
		end
	end

	-- Inisialisasi state awal
	resetAllBorders()
	setEquipButtonState()

	-- Update CanvasSize setelah semua item ditambahkan
	-- Menggunakan GetPropertyChangedSignal untuk menunggu perubahan ukuran konten
	sl_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Once(function()
		skinListFrame.CanvasSize = UDim2.new(0, sl_layout.AbsoluteContentSize.X, 0, 0)
	end)
end

-- Tombol untuk membuka menu inventaris
inventoryButton.MouseButton1Click:Connect(function()
	if not inventoryData then
		inventoryData = inventoryRemote:InvokeServer()
	end
	createCategoryButtons() -- Buat tombol filter
	updateWeaponList(selectedCategory) -- Tampilkan daftar senjata awal
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
local minValue, maxValue = 2.5, 10 -- Diubah dari 2 ke 4

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
